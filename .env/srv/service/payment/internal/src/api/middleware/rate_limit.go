// internal/adapters/http/middleware/rate_limit.go
package middleware

import (
	"encoding/json"
	"net/http"
	"sync"

	"payment-service/pkg/errors"
	"payment-service/pkg/logger"

	"golang.org/x/time/rate"
)

type RateLimitMiddleware struct {
	limiters map[string]*rate.Limiter
	mu       sync.RWMutex
	rps      int
	burst    int
	logger   logger.Logger
}

func NewRateLimitMiddleware(rps, burst int, logger logger.Logger) *RateLimitMiddleware {
	return &RateLimitMiddleware{
		limiters: make(map[string]*rate.Limiter),
		rps:      rps,
		burst:    burst,
		logger:   logger,
	}
}

func (m *RateLimitMiddleware) RateLimit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		clientID := m.getClientID(r)

		limiter := m.getLimiter(clientID)
		if !limiter.Allow() {
			m.logger.Warn("Rate limit exceeded", map[string]interface{}{
				"client_id":   clientID,
				"remote_addr": r.RemoteAddr,
				"path":        r.URL.Path,
			})

			err := errors.AppError{
				Type:       errors.ErrorTypeBadRequest,
				Code:       "RATE_LIMIT_EXCEEDED",
				Message:    "Rate limit exceeded",
				HTTPStatus: http.StatusTooManyRequests,
			}

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(err.HTTPStatus)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"type":    err.Type,
				"code":    err.Code,
				"message": err.Message,
			})
			return
		}

		next.ServeHTTP(w, r)
	})
}

func (m *RateLimitMiddleware) getLimiter(clientID string) *rate.Limiter {
	m.mu.RLock()
	limiter, exists := m.limiters[clientID]
	m.mu.RUnlock()

	if !exists {
		m.mu.Lock()
		limiter = rate.NewLimiter(rate.Limit(m.rps), m.burst)
		m.limiters[clientID] = limiter
		m.mu.Unlock()
	}

	return limiter
}

func (m *RateLimitMiddleware) getClientID(r *http.Request) string {
	if clientID := r.Context().Value("client_id"); clientID != nil {
		return clientID.(string)
	}
	return r.RemoteAddr
}

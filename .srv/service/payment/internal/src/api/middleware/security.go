// internal/adapters/http/middleware/security.go
package middleware

import (
	"crypto/subtle"
	"net/http"
	"strings"

	"payment-service/pkg/logger"
)

type SecurityMiddleware struct {
	logger logger.Logger
}

func NewSecurityMiddleware(logger logger.Logger) *SecurityMiddleware {
	return &SecurityMiddleware{logger: logger}
}

func (s *SecurityMiddleware) SecurityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Security headers
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("X-XSS-Protection", "1; mode=block")
		w.Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		w.Header().Set("Content-Security-Policy", "default-src 'self'")
		w.Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")

		next.ServeHTTP(w, r)
	})
}

func (s *SecurityMiddleware) APIKeyAuth(apiKey string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if apiKey == "" {
				next.ServeHTTP(w, r)
				return
			}

			providedKey := r.Header.Get("X-API-Key")
			if providedKey == "" {
				http.Error(w, "API key required", http.StatusUnauthorized)
				return
			}

			if subtle.ConstantTimeCompare([]byte(providedKey), []byte(apiKey)) != 1 {
				s.logger.Warn("Invalid API key attempt", map[string]interface{}{
					"ip":         r.RemoteAddr,
					"user_agent": r.UserAgent(),
					"path":       r.URL.Path,
				})
				http.Error(w, "Invalid API key", http.StatusUnauthorized)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

func (s *SecurityMiddleware) IPWhitelist(allowedIPs []string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if len(allowedIPs) == 0 {
				next.ServeHTTP(w, r)
				return
			}

			clientIP := s.getClientIP(r)

			for _, allowedIP := range allowedIPs {
				if allowedIP == "*" || allowedIP == clientIP {
					next.ServeHTTP(w, r)
					return
				}
			}

			s.logger.Warn("IP not in whitelist", map[string]interface{}{
				"ip":         clientIP,
				"user_agent": r.UserAgent(),
				"path":       r.URL.Path,
			})

			http.Error(w, "Access denied", http.StatusForbidden)
		})
	}
}

func (s *SecurityMiddleware) getClientIP(r *http.Request) string {
	// Check X-Forwarded-For header
	xff := r.Header.Get("X-Forwarded-For")
	if xff != "" {
		ips := strings.Split(xff, ",")
		return strings.TrimSpace(ips[0])
	}

	// Check X-Real-IP header
	xri := r.Header.Get("X-Real-IP")
	if xri != "" {
		return xri
	}

	return r.RemoteAddr
}

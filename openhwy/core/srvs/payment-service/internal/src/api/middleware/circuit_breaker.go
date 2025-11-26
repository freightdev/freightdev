// internal/adapters/http/middleware/circuit_breaker.go
package middleware

import (
	"encoding/json"
	"net/http"
	"sync"
	"time"

	"payment-service/pkg/logger"
)

type CircuitBreakerState int

const (
	StateClosed CircuitBreakerState = iota
	StateOpen
	StateHalfOpen
)

type CircuitBreaker struct {
	mu              sync.RWMutex
	state           CircuitBreakerState
	failures        int64
	requests        int64
	lastFailureTime time.Time
	lastSuccessTime time.Time

	// Configuration
	maxFailures      int64
	timeout          time.Duration
	resetTimeout     time.Duration
	failureThreshold float64

	logger logger.Logger
}

func NewCircuitBreaker(maxFailures int64, timeout, resetTimeout time.Duration, logger logger.Logger) *CircuitBreaker {
	return &CircuitBreaker{
		state:            StateClosed,
		maxFailures:      maxFailures,
		timeout:          timeout,
		resetTimeout:     resetTimeout,
		failureThreshold: 0.6,
		logger:           logger,
	}
}

func (cb *CircuitBreaker) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !cb.allowRequest() {
			cb.logger.Warn("Circuit breaker is open, rejecting request", map[string]interface{}{
				"path":     r.URL.Path,
				"method":   r.Method,
				"failures": cb.failures,
				"requests": cb.requests,
			})

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusServiceUnavailable)
			json.NewEncoder(w).Encode(map[string]interface{}{
				"error": map[string]interface{}{
					"code":    "SERVICE_UNAVAILABLE",
					"message": "Service temporarily unavailable",
				},
			})
			return
		}

		// Wrap response writer to capture status code
		wrapper := &statusCapture{ResponseWriter: w, statusCode: http.StatusOK}

		start := time.Now()
		next.ServeHTTP(wrapper, r)
		duration := time.Since(start)

		// Record the result
		if wrapper.statusCode >= 500 || duration > cb.timeout {
			cb.recordFailure()
		} else {
			cb.recordSuccess()
		}
	})
}

func (cb *CircuitBreaker) allowRequest() bool {
	cb.mu.RLock()
	defer cb.mu.RUnlock()

	now := time.Now()

	switch cb.state {
	case StateClosed:
		return true
	case StateOpen:
		if now.After(cb.lastFailureTime.Add(cb.resetTimeout)) {
			cb.mu.RUnlock()
			cb.mu.Lock()
			if cb.state == StateOpen {
				cb.state = StateHalfOpen
				cb.logger.Info("Circuit breaker transitioning to half-open", nil)
			}
			cb.mu.Unlock()
			cb.mu.RLock()
			return true
		}
		return false
	case StateHalfOpen:
		return true
	default:
		return false
	}
}

func (cb *CircuitBreaker) recordSuccess() {
	cb.mu.Lock()
	defer cb.mu.Unlock()

	cb.requests++
	cb.lastSuccessTime = time.Now()

	if cb.state == StateHalfOpen {
		cb.state = StateClosed
		cb.failures = 0
		cb.logger.Info("Circuit breaker closed after successful request", nil)
	}
}

func (cb *CircuitBreaker) recordFailure() {
	cb.mu.Lock()
	defer cb.mu.Unlock()

	cb.requests++
	cb.failures++
	cb.lastFailureTime = time.Now()

	failureRate := float64(cb.failures) / float64(cb.requests)

	if cb.state == StateClosed && (cb.failures >= cb.maxFailures || failureRate >= cb.failureThreshold) {
		cb.state = StateOpen
		cb.logger.Warn("Circuit breaker opened", map[string]interface{}{
			"failures":     cb.failures,
			"requests":     cb.requests,
			"failure_rate": failureRate,
		})
	} else if cb.state == StateHalfOpen {
		cb.state = StateOpen
		cb.logger.Warn("Circuit breaker opened from half-open state", nil)
	}
}

type statusCapture struct {
	http.ResponseWriter
	statusCode int
}

func (sc *statusCapture) WriteHeader(code int) {
	sc.statusCode = code
	sc.ResponseWriter.WriteHeader(code)
}

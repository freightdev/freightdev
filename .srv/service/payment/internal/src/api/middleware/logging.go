// internal/adapters/http/middleware/logging.go
package middleware

import (
	"context"
	"net/http"
	"time"

	"payment-service/pkg/logger"
)

type LoggingMiddleware struct {
	logger logger.Logger
}

func NewLoggingMiddleware(logger logger.Logger) *LoggingMiddleware {
	return &LoggingMiddleware{logger: logger}
}

func (m *LoggingMiddleware) LogRequest(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Create response writer wrapper to capture status code
		wrapper := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		correlationID := r.Header.Get("X-Correlation-ID")
		if correlationID == "" {
			correlationID = generateCorrelationID()
		}

		// Add correlation ID to context
		ctx := context.WithValue(r.Context(), "correlation_id", correlationID)

		// Add correlation ID to response header
		wrapper.Header().Set("X-Correlation-ID", correlationID)

		next.ServeHTTP(wrapper, r.WithContext(ctx))

		duration := time.Since(start)

		m.logger.Info("HTTP request completed", map[string]interface{}{
			"correlation_id": correlationID,
			"method":         r.Method,
			"path":           r.URL.Path,
			"status_code":    wrapper.statusCode,
			"duration_ms":    duration.Milliseconds(),
			"remote_addr":    r.RemoteAddr,
			"user_agent":     r.UserAgent(),
		})
	})
}

type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

func generateCorrelationID() string {
	return uuid.New().String()
}

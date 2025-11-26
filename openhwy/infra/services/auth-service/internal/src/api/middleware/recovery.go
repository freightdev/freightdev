// internal/middleware/recovery.go
package middleware

import (
	"log/slog"
	"net/http"
	"runtime/debug"

	"auth-service/internal/shared/errors"
)

// RecoveryMiddleware provides panic recovery
type RecoveryMiddleware struct {
	logger *slog.Logger
}

// NewRecoveryMiddleware creates a new recovery middleware
func NewRecoveryMiddleware(logger *slog.Logger) *RecoveryMiddleware {
	return &RecoveryMiddleware{
		logger: logger,
	}
}

// Recover recovers from panics and returns a 500 error
func (m *RecoveryMiddleware) Recover(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				m.logger.Error("Panic recovered",
					slog.Any("error", err),
					slog.String("path", r.URL.Path),
					slog.String("method", r.Method),
					slog.String("stack", string(debug.Stack())),
				)

				writeErrorResponse(w, errors.ErrInternalServer())
			}
		}()

		next.ServeHTTP(w, r)
	})
}

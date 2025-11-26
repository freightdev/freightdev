// internal/middleware/auth.go
package middleware

import (
	"context"
	"net/http"
	"strings"

	"auth-service/internal/domain/services"
	"auth-service/internal/shared/errors"
)

type contextKey string

const (
	UserIDKey    contextKey = "user_id"
	UserEmailKey contextKey = "user_email"
	UserRoleKey  contextKey = "user_role"
	ClientIPKey  contextKey = "client_ip"
	UserAgentKey contextKey = "user_agent"
)

// AuthMiddleware provides JWT authentication middleware
type AuthMiddleware struct {
	authService services.AuthService
}

// NewAuthMiddleware creates a new authentication middleware
func NewAuthMiddleware(authService services.AuthService) *AuthMiddleware {
	return &AuthMiddleware{
		authService: authService,
	}
}

// RequireAuth middleware that requires a valid JWT token
func (m *AuthMiddleware) RequireAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := extractBearerToken(r)
		if token == "" {
			writeErrorResponse(w, errors.ErrUnauthorized())
			return
		}

		claims, err := m.authService.ValidateToken(r.Context(), token)
		if err != nil {
			writeErrorResponse(w, err)
			return
		}

		// Add user info to context
		ctx := r.Context()
		ctx = context.WithValue(ctx, UserIDKey, claims.UserID)
		ctx = context.WithValue(ctx, UserEmailKey, claims.Email)
		ctx = context.WithValue(ctx, UserRoleKey, claims.Role)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// RequireRole middleware that requires a specific role
func (m *AuthMiddleware) RequireRole(role string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			userRole := getUserRoleFromContext(r.Context())
			if userRole != role {
				writeErrorResponse(w, errors.ErrForbidden())
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

// OptionalAuth middleware that adds user info if token is present but doesn't require it
func (m *AuthMiddleware) OptionalAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := extractBearerToken(r)
		if token != "" {
			if claims, err := m.authService.ValidateToken(r.Context(), token); err == nil {
				ctx := r.Context()
				ctx = context.WithValue(ctx, UserIDKey, claims.UserID)
				ctx = context.WithValue(ctx, UserEmailKey, claims.Email)
				ctx = context.WithValue(ctx, UserRoleKey, claims.Role)
				r = r.WithContext(ctx)
			}
		}
		next.ServeHTTP(w, r)
	})
}

// extractBearerToken extracts the JWT token from Authorization header
func extractBearerToken(r *http.Request) string {
	auth := r.Header.Get("Authorization")
	if !strings.HasPrefix(auth, "Bearer ") {
		return ""
	}
	return strings.TrimPrefix(auth, "Bearer ")
}

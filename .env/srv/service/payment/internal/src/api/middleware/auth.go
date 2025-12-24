// internal/adapters/http/middleware/auth.go
package middleware

import (
	"context"
	"encoding/json"
	"net/http"
	"strings"

	"payment-service/pkg/errors"
	"payment-service/pkg/logger"

	"github.com/golang-jwt/jwt/v5"
)

type AuthMiddleware struct {
	jwtSecret string
	logger    logger.Logger
}

func NewAuthMiddleware(jwtSecret string, logger logger.Logger) *AuthMiddleware {
	return &AuthMiddleware{
		jwtSecret: jwtSecret,
		logger:    logger,
	}
}

func (m *AuthMiddleware) Authenticate(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			m.respondUnauthorized(w, "MISSING_TOKEN", "Authorization header is required")
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || parts[0] != "Bearer" {
			m.respondUnauthorized(w, "INVALID_TOKEN_FORMAT", "Authorization header format should be 'Bearer {token}'")
			return
		}

		tokenString := parts[1]
		claims := jwt.MapClaims{}

		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return []byte(m.jwtSecret), nil
		})

		if err != nil || !token.Valid {
			m.respondUnauthorized(w, "INVALID_TOKEN", "Token is invalid or expired")
			return
		}

		// Extract client info from token
		clientID, ok := claims["client_id"].(string)
		if !ok {
			m.respondUnauthorized(w, "INVALID_TOKEN_CLAIMS", "Token missing required claims")
			return
		}

		// Add client info to context
		ctx := context.WithValue(r.Context(), "client_id", clientID)
		if sub, ok := claims["sub"].(string); ok {
			ctx = context.WithValue(ctx, "user_id", sub)
		}

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func (m *AuthMiddleware) respondUnauthorized(w http.ResponseWriter, code, message string) {
	err := errors.NewUnauthorizedError(code, message)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(err.HTTPStatus)

	response := map[string]interface{}{
		"type":    err.Type,
		"code":    err.Code,
		"message": err.Message,
	}

	json.NewEncoder(w).Encode(response)
}

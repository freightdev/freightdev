// internal/middleware/utils.go
package middleware

import (
	"context"
	"encoding/json"
	"net/http"

	"auth-service/internal/shared/errors"

	"github.com/google/uuid"
)

// setClientInfoToContext adds client IP and User-Agent to context
func setClientInfoToContext(ctx context.Context, r *http.Request) context.Context {
	// Extract real IP (considering proxies)
	ip := r.Header.Get("X-Real-IP")
	if ip == "" {
		ip = r.Header.Get("X-Forwarded-For")
		if ip == "" {
			ip = r.RemoteAddr
		}
	}

	ctx = context.WithValue(ctx, ClientIPKey, ip)
	ctx = context.WithValue(ctx, UserAgentKey, r.UserAgent())
	return ctx
}

// Context helper functions
func getUserIDFromContext(ctx context.Context) uuid.UUID {
	if userID, ok := ctx.Value(UserIDKey).(uuid.UUID); ok {
		return userID
	}
	return uuid.Nil
}

func getUserEmailFromContext(ctx context.Context) string {
	if email, ok := ctx.Value(UserEmailKey).(string); ok {
		return email
	}
	return ""
}

func getUserRoleFromContext(ctx context.Context) string {
	if role, ok := ctx.Value(UserRoleKey).(string); ok {
		return role
	}
	return ""
}

// writeJSONResponse writes a JSON response
func writeJSONResponse(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(data)
}

// writeErrorResponse writes an error response
func writeErrorResponse(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "application/json")

	if appErr, ok := err.(*errors.AppError); ok {
		w.WriteHeader(appErr.HTTPStatus)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": map[string]interface{}{
				"code":    appErr.Code,
				"message": appErr.Message,
				"details": appErr.Details,
			},
		})
		return
	}

	// Generic error response
	w.WriteHeader(http.StatusInternalServerError)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"error": map[string]interface{}{
			"code":    "INTERNAL_SERVER_ERROR",
			"message": "An unexpected error occurred",
		},
	})
}

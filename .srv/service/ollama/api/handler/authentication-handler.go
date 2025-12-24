// Ollama Control Service - OCS
// Repo = github.com/freigthdev/main/ocs
// Path = api/handler/authentication-handler.go

package handler

import (
	// stdlib
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	// third-party
	"github.com/golang-jwt/jwt/v4"
	"github.com/rs/zerolog/log"

	// internal
	"ocs/managers"
)

// AuthenticationHandler handles user authentication
type AuthenticationHandler struct {
	configManager  *managers.ConfigManager
	sessionManager *managers.SessionManager
	tokenManager   *managers.TokenManager
	secretKey      []byte
}

// NewAuthenticationHandler creates a new authentication handler
func NewAuthenticationHandler(
	configManager *managers.ConfigManager,
	sessionManager *managers.SessionManager,
	tokenManager *managers.TokenManager,
) *AuthenticationHandler {
	secretKey := []byte("your-secret-key") // TODO: Load from config or env
	return &AuthenticationHandler{
		configManager:  configManager,
		sessionManager: sessionManager,
		tokenManager:   tokenManager,
		secretKey:      secretKey,
	}
}

// Authenticate handles user login and JWT issuance
func (ah *AuthenticationHandler) Authenticate(w http.ResponseWriter, r *http.Request) {
	var req struct {
		UserID   string `json:"user_id"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	// TODO: Replace with actual user validation (e.g., database check)
	if req.UserID == "" || req.Password == "" {
		http.Error(w, "missing user_id or password", http.StatusBadRequest)
		return
	}

	// Create session
	session, err := ah.sessionManager.CreateSession(r.Context(), req.UserID, "", nil)
	if err != nil {
		http.Error(w, fmt.Sprintf("failed to create session: %v", err), http.StatusInternalServerError)
		return
	}

	// Generate JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":    req.UserID,
		"session_id": session.ID,
		"exp":        time.Now().Add(24 * time.Hour).Unix(),
	})
	tokenString, err := token.SignedString(ah.secretKey)
	if err != nil {
		http.Error(w, "failed to generate token", http.StatusInternalServerError)
		return
	}

	response := map[string]string{
		"token":      tokenString,
		"session_id": session.ID,
	}
	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Error().Err(err).Msg("Failed to encode auth response")
	}

	log.Info().Str("user_id", req.UserID).Str("session_id", session.ID).Msg("User authenticated")
}

// Middleware authenticates requests using JWT
func (ah *AuthenticationHandler) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, "missing Authorization header", http.StatusUnauthorized)
			return
		}

		if !strings.HasPrefix(authHeader, "Bearer ") {
			http.Error(w, "invalid Authorization format", http.StatusUnauthorized)
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			return ah.secretKey, nil
		})

		if err != nil || !token.Valid {
			http.Error(w, "invalid token", http.StatusUnauthorized)
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			http.Error(w, "invalid token claims", http.StatusUnauthorized)
			return
		}

		userID, ok := claims["user_id"].(string)
		sessionID, ok2 := claims["session_id"].(string)
		if !ok || !ok2 || userID == "" || sessionID == "" {
			http.Error(w, "invalid token claims", http.StatusUnauthorized)
			return
		}

		// Verify session
		if _, exists := ah.sessionManager.GetSession(sessionID); !exists {
			http.Error(w, "session not found", http.StatusUnauthorized)
			return
		}

		// Add user_id and session_id to context
		ctx := context.WithValue(r.Context(), "user_id", userID)
		ctx = context.WithValue(ctx, "session_id", sessionID)
		next.ServeHTTP(w, r.WithContext(ctx))

		log.Info().Str("user_id", userID).Str("session_id", sessionID).Msg("Authenticated request")
	})
}

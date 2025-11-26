// internal/handlers/auth.go
package handlers

import (
	"encoding/json"
	"net/http"
	"strings"

	"auth-service/internal/domain/services"
	"auth-service/internal/shared/errors"
	"auth-service/internal/shared/types"

	"github.com/go-playground/validator/v10"
)

// AuthHandler handles authentication-related HTTP requests
type AuthHandler struct {
	authService services.AuthService
	userService services.UserService
	validator   *validator.Validate
}

// NewAuthHandler creates a new authentication handler
func NewAuthHandler(authService services.AuthService, userService services.UserService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		userService: userService,
		validator:   validator.New(),
	}
}

// Login handles user login requests
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req types.LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed("Invalid JSON format"))
		return
	}

	if err := h.validator.Struct(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed(err.Error()))
		return
	}

	ctx := r.Context()
	// Add IP and User-Agent to context
	ctx = setClientInfoToContext(ctx, r)

	authResponse, err := h.authService.Login(ctx, &req)
	if err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, authResponse)
}

// Register handles user registration requests
func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req types.RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed("Invalid JSON format"))
		return
	}

	if err := h.validator.Struct(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed(err.Error()))
		return
	}

	userInfo, err := h.userService.Register(r.Context(), &req)
	if err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusCreated, map[string]interface{}{
		"user":    userInfo,
		"message": "Registration successful. Please check your email for verification.",
	})
}

// RefreshToken handles token refresh requests
func (h *AuthHandler) RefreshToken(w http.ResponseWriter, r *http.Request) {
	var req types.RefreshTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed("Invalid JSON format"))
		return
	}

	if err := h.validator.Struct(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed(err.Error()))
		return
	}

	authResponse, err := h.authService.RefreshToken(r.Context(), &req)
	if err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, authResponse)
}

// Logout handles user logout requests
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())
	sessionToken := getRefreshTokenFromRequest(r)

	if sessionToken == "" {
		writeErrorResponse(w, errors.ErrValidationFailed("Refresh token required"))
		return
	}

	if err := h.authService.Logout(r.Context(), userID, sessionToken); err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, map[string]string{
		"message": "Logout successful",
	})
}

// LogoutAll handles logout from all sessions
func (h *AuthHandler) LogoutAll(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())

	if err := h.authService.LogoutAll(r.Context(), userID); err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, map[string]string{
		"message": "Logged out from all sessions",
	})
}

// ChangePassword handles password change requests
func (h *AuthHandler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	var req types.ChangePasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed("Invalid JSON format"))
		return
	}

	if err := h.validator.Struct(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed(err.Error()))
		return
	}

	userID := getUserIDFromContext(r.Context())
	if err := h.userService.ChangePassword(r.Context(), userID, &req); err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, map[string]string{
		"message": "Password changed successfully",
	})
}

// RequestPasswordReset handles password reset requests
func (h *AuthHandler) RequestPasswordReset(w http.ResponseWriter, r *http.Request) {
	var req types.ResetPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed("Invalid JSON format"))
		return
	}

	if err := h.validator.Struct(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed(err.Error()))
		return
	}

	if err := h.userService.RequestPasswordReset(r.Context(), &req); err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, map[string]string{
		"message": "If the email exists, a reset link has been sent",
	})
}

// ConfirmPasswordReset handles password reset confirmation
func (h *AuthHandler) ConfirmPasswordReset(w http.ResponseWriter, r *http.Request) {
	var req types.ConfirmResetPasswordRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed("Invalid JSON format"))
		return
	}

	if err := h.validator.Struct(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed(err.Error()))
		return
	}

	if err := h.userService.ConfirmPasswordReset(r.Context(), &req); err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, map[string]string{
		"message": "Password reset successful",
	})
}

// VerifyEmail handles email verification
func (h *AuthHandler) VerifyEmail(w http.ResponseWriter, r *http.Request) {
	token := r.URL.Query().Get("token")
	if token == "" {
		writeErrorResponse(w, errors.ErrValidationFailed("Verification token required"))
		return
	}

	if err := h.userService.VerifyEmail(r.Context(), token); err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, map[string]string{
		"message": "Email verified successfully",
	})
}

// GetProfile handles profile retrieval
func (h *AuthHandler) GetProfile(w http.ResponseWriter, r *http.Request) {
	userID := getUserIDFromContext(r.Context())

	profile, err := h.userService.GetProfile(r.Context(), userID)
	if err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, profile)
}

// UpdateProfile handles profile updates
func (h *AuthHandler) UpdateProfile(w http.ResponseWriter, r *http.Request) {
	var req types.UpdateProfileRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed("Invalid JSON format"))
		return
	}

	if err := h.validator.Struct(&req); err != nil {
		writeErrorResponse(w, errors.ErrValidationFailed(err.Error()))
		return
	}

	userID := getUserIDFromContext(r.Context())
	profile, err := h.userService.UpdateProfile(r.Context(), userID, &req)
	if err != nil {
		writeErrorResponse(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, profile)
}

// Health check endpoint
func (h *AuthHandler) Health(w http.ResponseWriter, r *http.Request) {
	writeJSONResponse(w, http.StatusOK, map[string]string{
		"status":  "healthy",
		"service": "auth-service",
	})
}

// Helper functions
func getRefreshTokenFromRequest(r *http.Request) string {
	// Try to get from body first (for logout requests)
	var body struct {
		RefreshToken string `json:"refresh_token"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err == nil && body.RefreshToken != "" {
		return body.RefreshToken
	}

	// Try to get from Authorization header as fallback
	auth := r.Header.Get("Authorization")
	if strings.HasPrefix(auth, "Bearer ") {
		return strings.TrimPrefix(auth, "Bearer ")
	}

	return ""
}

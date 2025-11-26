// internal/application/handlers/http/user_handler.go
package http

import (
	"net/http"
	"user_service/internal/application/dto/requests"
	"user_service/internal/application/dto/responses"
	"user_service/internal/application/services"
	"user_service/internal/shared/errors"
	"user_service/internal/shared/logger"
	"user_service/internal/shared/middleware"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

type UserHandler struct {
	userService services.UserApplicationService
	logger      logger.Logger
}

func NewUserHandler(userService services.UserApplicationService, logger logger.Logger) *UserHandler {
	return &UserHandler{
		userService: userService,
		logger:      logger,
	}
}

// RegisterRoutes registers all user-related routes
func (h *UserHandler) RegisterRoutes(router *gin.RouterGroup) {
	users := router.Group("/users")
	{
		users.POST("/", h.CreateUser)
		users.GET("/", h.ListUsers)
		users.GET("/:id", h.GetUserByID)
		users.PUT("/:id", h.UpdateUser)
		users.DELETE("/:id", h.DeleteUser)
		users.POST("/:id/activate", h.ActivateUser)
		users.POST("/:id/suspend", h.SuspendUser)
		users.POST("/:id/change-password", h.ChangePassword)
		users.PUT("/:id/profile", h.UpdateProfile)

		// Additional query endpoints
		users.GET("/email/:email", h.GetUserByEmail)
		users.GET("/username/:username", h.GetUserByUsername)
	}
}

func (h *UserHandler) CreateUser(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())

	var req requests.CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid request body"), requestID)
		return
	}

	result, err := h.userService.CreateUser(c.Request.Context(), &req)
	if err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(result, "User created successfully", requestID)
	c.JSON(http.StatusCreated, response)
}

func (h *UserHandler) GetUserByID(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())

	id, err := h.parseUUID(c.Param("id"))
	if err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid user ID"), requestID)
		return
	}

	user, err := h.userService.GetUserByID(c.Request.Context(), id)
	if err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(user, "User retrieved successfully", requestID)
	c.JSON(http.StatusOK, response)
}

func (h *UserHandler) GetUserByEmail(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())
	email := c.Param("email")

	user, err := h.userService.GetUserByEmail(c.Request.Context(), email)
	if err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(user, "User retrieved successfully", requestID)
	c.JSON(http.StatusOK, response)
}

func (h *UserHandler) GetUserByUsername(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())
	username := c.Param("username")

	user, err := h.userService.GetUserByUsername(c.Request.Context(), username)
	if err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(user, "User retrieved successfully", requestID)
	c.JSON(http.StatusOK, response)
}

func (h *UserHandler) UpdateUser(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())

	id, err := h.parseUUID(c.Param("id"))
	if err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid user ID"), requestID)
		return
	}

	var req requests.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid request body"), requestID)
		return
	}

	user, err := h.userService.UpdateUser(c.Request.Context(), id, &req)
	if err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(user, "User updated successfully", requestID)
	c.JSON(http.StatusOK, response)
}

func (h *UserHandler) DeleteUser(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())

	id, err := h.parseUUID(c.Param("id"))
	if err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid user ID"), requestID)
		return
	}

	if err := h.userService.DeleteUser(c.Request.Context(), id); err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(nil, "User deleted successfully", requestID)
	c.JSON(http.StatusOK, response)
}

func (h *UserHandler) ListUsers(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())

	var req requests.ListUsersRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid query parameters"), requestID)
		return
	}

	users, err := h.userService.ListUsers(c.Request.Context(), &req)
	if err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(users, "Users retrieved successfully", requestID)
	c.JSON(http.StatusOK, response)
}

func (h *UserHandler) ActivateUser(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())

	id, err := h.parseUUID(c.Param("id"))
	if err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid user ID"), requestID)
		return
	}

	user, err := h.userService.ActivateUser(c.Request.Context(), id)
	if err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(user, "User activated successfully", requestID)
	c.JSON(http.StatusOK, response)
}

func (h *UserHandler) SuspendUser(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())

	id, err := h.parseUUID(c.Param("id"))
	if err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid user ID"), requestID)
		return
	}

	user, err := h.userService.SuspendUser(c.Request.Context(), id)
	if err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(user, "User suspended successfully", requestID)
	c.JSON(http.StatusOK, response)
}

func (h *UserHandler) ChangePassword(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())

	id, err := h.parseUUID(c.Param("id"))
	if err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid user ID"), requestID)
		return
	}

	var req requests.ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid request body"), requestID)
		return
	}

	if err := h.userService.ChangePassword(c.Request.Context(), id, &req); err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(nil, "Password changed successfully", requestID)
	c.JSON(http.StatusOK, response)
}

func (h *UserHandler) UpdateProfile(c *gin.Context) {
	requestID := middleware.GetRequestID(c.Request.Context())

	id, err := h.parseUUID(c.Param("id"))
	if err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid user ID"), requestID)
		return
	}

	var req requests.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		h.respondWithError(c, errors.NewValidationError("invalid request body"), requestID)
		return
	}

	profile, err := h.userService.UpdateProfile(c.Request.Context(), id, &req)
	if err != nil {
		h.respondWithError(c, err, requestID)
		return
	}

	response := responses.NewSuccessResponse(profile, "Profile updated successfully", requestID)
	c.JSON(http.StatusOK, response)
}

// Helper methods
func (h *UserHandler) parseUUID(str string) (uuid.UUID, error) {
	return uuid.Parse(str)
}

func (h *UserHandler) respondWithError(c *gin.Context, err error, requestID string) {
	var appErr *errors.AppError
	if errors.As(err, &appErr) {
		response := responses.NewErrorResponse(appErr.Message, requestID)
		c.JSON(appErr.StatusCode, response)

		h.logger.Error("Request failed",
			zap.String("request_id", requestID),
			zap.String("error_type", string(appErr.Type)),
			zap.String("error_message", appErr.Message),
			zap.Error(appErr.Cause),
		)
	} else {
		response := responses.NewErrorResponse("Internal server error", requestID)
		c.JSON(http.StatusInternalServerError, response)

		h.logger.Error("Unexpected error",
			zap.String("request_id", requestID),
			zap.Error(err),
		)
	}
}

// internal/shared/middleware/middleware.go (same file for brevity)
package middleware

import (
	"context"
	"net/http"
	"time"
	"user_service/internal/shared/errors"
	"user_service/internal/shared/logger"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

const (
	RequestIDKey = "request_id"
	UserIDKey    = "user_id"
)

func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if requestID == "" {
			requestID = uuid.New().String()
		}

		c.Set(RequestIDKey, requestID)
		c.Header("X-Request-ID", requestID)
		c.Next()
	}
}

func Logger(log logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		method := c.Request.Method

		requestID, _ := c.Get(RequestIDKey)

		log.Info("HTTP request started",
			zap.String("method", method),
			zap.String("path", path),
			zap.String("request_id", requestID.(string)),
			zap.String("client_ip", c.ClientIP()),
			zap.String("user_agent", c.GetHeader("User-Agent")),
		)

		c.Next()

		duration := time.Since(start)
		status := c.Writer.Status()

		logFields := []zap.Field{
			zap.String("method", method),
			zap.String("path", path),
			zap.String("request_id", requestID.(string)),
			zap.Int("status", status),
			zap.Duration("duration", duration),
			zap.Int("response_size", c.Writer.Size()),
		}

		if status >= 400 {
			log.Error("HTTP request completed with error", logFields...)
		} else {
			log.Info("HTTP request completed", logFields...)
		}
	}
}

func ErrorHandler(log logger.Logger) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()

		if len(c.Errors) > 0 {
			err := c.Errors.Last()

			var appErr *errors.AppError
			if errors.As(err.Err, &appErr) {
				c.JSON(appErr.StatusCode, gin.H{
					"error":   appErr.Type,
					"message": appErr.Message,
					"details": appErr.Details,
				})
			} else {
				log.Error("Unhandled error", zap.Error(err.Err))
				c.JSON(http.StatusInternalServerError, gin.H{
					"error":   "INTERNAL_ERROR",
					"message": "An internal server error occurred",
				})
			}
		}
	}
}

func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Accept, Authorization, X-Request-ID")
		c.Header("Access-Control-Expose-Headers", "X-Request-ID")
		c.Header("Access-Control-Max-Age", "86400")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	}
}

func Recovery(log logger.Logger) gin.HandlerFunc {
	return gin.CustomRecovery(func(c *gin.Context, recovered interface{}) {
		requestID, _ := c.Get(RequestIDKey)

		log.Error("Panic recovered",
			zap.String("request_id", requestID.(string)),
			zap.Any("panic", recovered),
			zap.String("path", c.Request.URL.Path),
			zap.String("method", c.Request.Method),
		)

		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "INTERNAL_ERROR",
			"message": "An internal server error occurred",
		})
	})
}

// Context helpers
func GetRequestID(ctx context.Context) string {
	if requestID, ok := ctx.Value(RequestIDKey).(string); ok {
		return requestID
	}
	return ""
}

func GetUserID(ctx context.Context) (*uuid.UUID, bool) {
	if userID, ok := ctx.Value(UserIDKey).(uuid.UUID); ok {
		return &userID, true
	}
	return nil, false
}

func WithRequestID(ctx context.Context, requestID string) context.Context {
	return context.WithValue(ctx, RequestIDKey, requestID)
}

func WithUserID(ctx context.Context, userID uuid.UUID) context.Context {
	return context.WithValue(ctx, UserIDKey, userID)
}

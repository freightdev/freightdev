// cmd/server/main.go
package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"user_service/internal/config"
	"user_service/internal/infrastructure/container"
	"user_service/internal/infrastructure/database/migrations"
	"user_service/internal/shared/middleware"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		fmt.Printf("Failed to load configuration: %v\n", err)
		os.Exit(1)
	}

	// Initialize container with all dependencies
	container, err := container.NewContainer(cfg)
	if err != nil {
		fmt.Printf("Failed to initialize container: %v\n", err)
		os.Exit(1)
	}
	defer container.Close()

	// Run database migrations
	if err := runMigrations(container); err != nil {
		container.Logger.Fatal("Failed to run migrations", zap.Error(err))
	}

	// Setup HTTP server
	server := setupHTTPServer(cfg, container)

	// Start server in a goroutine
	go func() {
		address := fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port)
		container.Logger.Info("Starting HTTP server", zap.String("address", address))

		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			container.Logger.Fatal("Failed to start server", zap.Error(err))
		}
	}()

	// Wait for interrupt signal to gracefully shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	container.Logger.Info("Shutting down server...")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), cfg.Server.ShutdownTimeout)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		container.Logger.Fatal("Server forced to shutdown", zap.Error(err))
	}

	container.Logger.Info("Server shutdown complete")
}

func runMigrations(container *container.Container) error {
	migrator := migrations.NewMigrator(container.Database.DB.DB, container.Logger)
	return migrator.Up()
}

func setupHTTPServer(cfg *config.Config, container *container.Container) *http.Server {
	// Set Gin mode based on environment
	if cfg.IsProduction() {
		gin.SetMode(gin.ReleaseMode)
	}

	// Create Gin router
	router := gin.New()

	// Add global middleware
	router.Use(middleware.RequestID())
	router.Use(middleware.Logger(container.Logger))
	router.Use(middleware.Recovery(container.Logger))
	router.Use(middleware.CORS())
	router.Use(middleware.ErrorHandler(container.Logger))

	// API routes group
	v1 := router.Group("/api/v1")
	{
		// Register handler routes
		container.HealthHandler.RegisterRoutes(v1)
		container.UserHandler.RegisterRoutes(v1)
	}

	// Root health check
	router.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"service": "user_service",
			"version": "1.0.0",
			"status":  "healthy",
		})
	})

	// Create HTTP server
	return &http.Server{
		Addr:         fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port),
		Handler:      router,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
		IdleTimeout:  cfg.Server.IdleTimeout,
	}
}

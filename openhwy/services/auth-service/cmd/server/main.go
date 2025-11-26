// cmd/server/main.go
package main

import (
	"context"
	"log"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/gorilla/mux"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"

	"your-org/auth-service/internal/config"
	"your-org/auth-service/internal/handlers"
	"your-org/auth-service/internal/middleware"
	"your-org/auth-service/internal/repositories/postgres"
	"your-org/auth-service/internal/services"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatal("Failed to load config:", err)
	}

	// Setup logger
	logger := setupLogger(cfg.Logger)
	slog.SetDefault(logger)

	// Setup database
	db, err := setupDatabase(cfg.Database)
	if err != nil {
		logger.Error("Failed to setup database", slog.Any("error", err))
		os.Exit(1)
	}
	defer db.Close()

	// Setup repositories
	userRepo := postgres.NewUserRepository(db)
	sessionRepo := postgres.NewSessionRepository(db)
	tokenBlacklistRepo := postgres.NewTokenBlacklistRepository(db)
	loginAttemptRepo := postgres.NewLoginAttemptRepository(db)

	// Setup services
	tokenService := services.NewTokenService(cfg, tokenBlacklistRepo)
	emailService := services.NewEmailService(cfg) // You'll need to implement this
	authService := services.NewAuthService(cfg, userRepo, sessionRepo, loginAttemptRepo, tokenService)
	userService := services.NewUserService(cfg, userRepo, tokenService, emailService)

	// Setup handlers
	authHandler := handlers.NewAuthHandler(authService, userService)

	// Setup middleware
	authMiddleware := middleware.NewAuthMiddleware(authService)
	loggingMiddleware := middleware.NewLoggingMiddleware(logger)
	recoveryMiddleware := middleware.NewRecoveryMiddleware(logger)
	corsMiddleware := middleware.NewCORSMiddleware(&cfg.Server.CORS)

	// Setup routes
	router := setupRoutes(authHandler, authMiddleware)

	// Apply global middleware
	handler := corsMiddleware.EnableCORS(
		loggingMiddleware.LogRequests(
			recoveryMiddleware.Recover(router)))

	// Setup server
	server := &http.Server{
		Addr:         cfg.Server.Host + ":" + cfg.Server.Port,
		Handler:      handler,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
	}

	// Start server in a goroutine
	go func() {
		logger.Info("Starting server", slog.String("addr", server.Addr))
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Error("Server failed to start", slog.Any("error", err))
			os.Exit(1)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Info("Shutting down server...")

	// Graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), cfg.Server.ShutdownTimeout)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		logger.Error("Server forced to shutdown", slog.Any("error", err))
		os.Exit(1)
	}

	logger.Info("Server exited")
}

func setupLogger(cfg config.LoggerConfig) *slog.Logger {
	var handler slog.Handler

	opts := &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}

	switch cfg.Level {
	case "debug":
		opts.Level = slog.LevelDebug
	case "warn":
		opts.Level = slog.LevelWarn
	case "error":
		opts.Level = slog.LevelError
	}

	if cfg.Format == "text" {
		handler = slog.NewTextHandler(os.Stdout, opts)
	} else {
		handler = slog.NewJSONHandler(os.Stdout, opts)
	}

	return slog.New(handler)
}

func setupDatabase(cfg config.DatabaseConfig) (*sqlx.DB, error) {
	db, err := sqlx.Connect("postgres", cfg.DSN())
	if err != nil {
		return nil, err
	}

	// Configure connection pool
	db.SetMaxOpenConns(cfg.MaxOpenConns)
	db.SetMaxIdleConns(cfg.MaxIdleConns)
	db.SetConnMaxLifetime(cfg.ConnMaxLifetime)

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, err
	}

	return db, nil
}

func setupRoutes(authHandler *handlers.AuthHandler, authMiddleware *middleware.AuthMiddleware) *mux.Router {
	router := mux.NewRouter()

	// Health check
	router.HandleFunc("/health", authHandler.Health).Methods("GET")

	// API routes
	api := router.PathPrefix("/api/v1").Subrouter()

	// Public routes (no auth required)
	api.HandleFunc("/auth/login", authHandler.Login).Methods("POST")
	api.HandleFunc("/auth/register", authHandler.Register).Methods("POST")
	api.HandleFunc("/auth/refresh", authHandler.RefreshToken).Methods("POST")
	api.HandleFunc("/auth/forgot-password", authHandler.RequestPasswordReset).Methods("POST")
	api.HandleFunc("/auth/reset-password", authHandler.ConfirmPasswordReset).Methods("POST")
	api.HandleFunc("/auth/verify-email", authHandler.VerifyEmail).Methods("GET")

	// Protected routes (auth required)
	protected := api.PathPrefix("").Subrouter()
	protected.Use(authMiddleware.RequireAuth)

	protected.HandleFunc("/auth/logout", authHandler.Logout).Methods("POST")
	protected.HandleFunc("/auth/logout-all", authHandler.LogoutAll).Methods("POST")
	protected.HandleFunc("/auth/change-password", authHandler.ChangePassword).Methods("POST")

	protected.HandleFunc("/profile", authHandler.GetProfile).Methods("GET")
	protected.HandleFunc("/profile", authHandler.UpdateProfile).Methods("PUT")

	return router
}

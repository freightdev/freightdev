// cmd/server/main.go
package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"payment-service/internal/adapters/external/notification"
	"payment-service/internal/adapters/external/stripe"
	httpAdapter "payment-service/internal/adapters/http"
	"payment-service/internal/adapters/repository/postgres"
	"payment-service/internal/config"
	"payment-service/internal/core/ports"
	"payment-service/internal/core/services"
	"payment-service/pkg/logger"
)

const (
	serviceName = "payment-service"
	version     = "1.0.0"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load configuration: %v\n", err)
		os.Exit(1)
	}

	// Initialize logger
	logLevel := logger.INFO
	switch cfg.Logging.Level {
	case "debug":
		logLevel = logger.DEBUG
	case "warn":
		logLevel = logger.WARN
	case "error":
		logLevel = logger.ERROR
	}

	log := logger.NewLogger(logLevel).With(map[string]interface{}{
		"service": serviceName,
		"version": version,
	})

	log.Info("Starting payment service", map[string]interface{}{
		"version": version,
		"port":    cfg.Server.Port,
	})

	// Initialize database
	dbConn, err := config.NewDatabaseConnection(cfg.Database)
	if err != nil {
		log.Error("Failed to connect to database", map[string]interface{}{
			"error": err.Error(),
		})
		os.Exit(1)
	}
	defer dbConn.Close()

	// Run database migrations
	if err := dbConn.RunMigrations(); err != nil {
		log.Error("Failed to run database migrations", map[string]interface{}{
			"error": err.Error(),
		})
		os.Exit(1)
	}

	log.Info("Database connected and migrations completed", nil)

	// Initialize repositories
	paymentRepo := postgres.NewPaymentRepository(dbConn.DB)
	transactionRepo := postgres.NewTransactionRepository(dbConn.DB)

	// Initialize payment processors
	processors := make(map[string]ports.PaymentProcessor)

	if stripeConfig, ok := cfg.Payment.Processors["stripe"]; ok {
		processors["stripe"] = stripe.NewStripeProcessor(stripeConfig, log)
		log.Info("Stripe processor initialized", nil)
	}

	// Initialize notification service
	webhookURL := os.Getenv("WEBHOOK_URL")
	notificationSvc := notification.NewWebhookNotificationService(webhookURL, log)

	// Initialize business services
	paymentService := services.NewPaymentService(
		paymentRepo,
		transactionRepo,
		processors,
		notificationSvc,
		log,
	)

	// Initialize HTTP router
	router := httpAdapter.NewRouter(paymentService, cfg, log)
	handler := router.SetupRoutes()

	// Initialize HTTP server
	server := &http.Server{
		Addr:         fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port),
		Handler:      handler,
		ReadTimeout:  cfg.Server.ReadTimeout,
		WriteTimeout: cfg.Server.WriteTimeout,
		IdleTimeout:  cfg.Server.IdleTimeout,
	}

	// Start server in a goroutine
	go func() {
		log.Info("HTTP server starting", map[string]interface{}{
			"address": server.Addr,
		})

		if cfg.Security.TLSEnabled {
			if err := server.ListenAndServeTLS(cfg.Security.TLSCertFile, cfg.Security.TLSKeyFile); err != nil && err != http.ErrServerClosed {
				log.Error("Failed to start HTTPS server", map[string]interface{}{
					"error": err.Error(),
				})
				os.Exit(1)
			}
		} else {
			if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
				log.Error("Failed to start HTTP server", map[string]interface{}{
					"error": err.Error(),
				})
				os.Exit(1)
			}
		}
	}()

	log.Info("Payment service started successfully", map[string]interface{}{
		"address": server.Addr,
		"tls":     cfg.Security.TLSEnabled,
	})

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Shutting down server...", nil)

	// Create a deadline to wait for
	ctx, cancel := context.WithTimeout(context.Background(), cfg.Server.ShutdownTimeout)
	defer cancel()

	// Attempt graceful shutdown
	if err := server.Shutdown(ctx); err != nil {
		log.Error("Server forced to shutdown", map[string]interface{}{
			"error": err.Error(),
		})
		os.Exit(1)
	}

	log.Info("Server exited", nil)
}

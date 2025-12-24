// internal/adapters/http/router.go
package http

import (
	"net/http"

	"payment-service/internal/adapters/http/handlers"
	"payment-service/internal/adapters/http/middleware"
	"payment-service/internal/config"
	"payment-service/internal/core/ports"
	"payment-service/pkg/logger"
	"payment-service/pkg/validator"

	"github.com/gorilla/mux"
)

type Router struct {
	router         *mux.Router
	paymentService ports.PaymentService
	config         *config.Config
	logger         logger.Logger
}

func NewRouter(
	paymentService ports.PaymentService,
	config *config.Config,
	logger logger.Logger,
) *Router {
	return &Router{
		router:         mux.NewRouter(),
		paymentService: paymentService,
		config:         config,
		logger:         logger,
	}
}

func (r *Router) SetupRoutes() http.Handler {
	// Initialize middleware
	authMiddleware := middleware.NewAuthMiddleware(r.config.Security.JWTSecret, r.logger)
	loggingMiddleware := middleware.NewLoggingMiddleware(r.logger)
	rateLimitMiddleware := middleware.NewRateLimitMiddleware(
		r.config.Security.RateLimitRPS,
		r.config.Security.RateLimitBurst,
		r.logger,
	)
	corsMiddleware := middleware.NewCORSMiddleware(r.config.Security.CORSAllowedOrigins)

	// Initialize handlers
	validator := validator.New()
	paymentHandler := handlers.NewPaymentHandler(r.paymentService, validator, r.logger)
	healthHandler := handlers.NewHealthHandler("1.0.0", r.logger)

	// Health check routes (no auth required)
	r.router.HandleFunc("/health", healthHandler.Health).Methods("GET")
	r.router.HandleFunc("/health/ready", healthHandler.Readiness).Methods("GET")
	r.router.HandleFunc("/health/live", healthHandler.Liveness).Methods("GET")

	// API routes with authentication
	api := r.router.PathPrefix("/api/v1").Subrouter()
	api.Use(corsMiddleware.CORS)
	api.Use(loggingMiddleware.LogRequest)
	api.Use(rateLimitMiddleware.RateLimit)
	api.Use(authMiddleware.Authenticate)

	// Payment routes
	api.HandleFunc("/payments", paymentHandler.CreatePayment).Methods("POST")
	api.HandleFunc("/payments", paymentHandler.ListPayments).Methods("GET")
	api.HandleFunc("/payments/{id}", paymentHandler.GetPayment).Methods("GET")
	api.HandleFunc("/payments/{id}/process", paymentHandler.ProcessPayment).Methods("POST")
	api.HandleFunc("/payments/{id}/refund", paymentHandler.RefundPayment).Methods("POST")
	api.HandleFunc("/payments/{id}/cancel", paymentHandler.CancelPayment).Methods("DELETE")

	return r.router
}

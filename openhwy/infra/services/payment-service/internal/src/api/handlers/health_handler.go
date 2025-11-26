// internal/adapters/http/handlers/health_handler.go
package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"payment-service/internal/adapters/http/dto"
	"payment-service/pkg/logger"
)

type HealthHandler struct {
	version string
	logger  logger.Logger
}

func NewHealthHandler(version string, logger logger.Logger) *HealthHandler {
	return &HealthHandler{
		version: version,
		logger:  logger,
	}
}

func (h *HealthHandler) Health(w http.ResponseWriter, r *http.Request) {
	response := dto.HealthResponse{
		Status:    "healthy",
		Version:   h.version,
		Timestamp: time.Now().UTC(),
		Services: map[string]string{
			"database": "healthy",
			"redis":    "healthy",
		},
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func (h *HealthHandler) Readiness(w http.ResponseWriter, r *http.Request) {
	// Add actual health checks here
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func (h *HealthHandler) Liveness(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

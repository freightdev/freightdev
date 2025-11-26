// internal/application/handlers/http/health_handler.go (same file for brevity)

type HealthHandler struct {
	logger logger.Logger
}

func NewHealthHandler(logger logger.Logger) *HealthHandler {
	return &HealthHandler{
		logger: logger,
	}
}

func (h *HealthHandler) RegisterRoutes(router *gin.RouterGroup) {
	health := router.Group("/health")
	{
		health.GET("/", h.HealthCheck)
		health.GET("/ready", h.ReadinessCheck)
		health.GET("/live", h.LivenessCheck)
	}
}

type HealthResponse struct {
	Status    string            `json:"status"`
	Timestamp string            `json:"timestamp"`
	Version   string            `json:"version,omitempty"`
	Checks    map[string]string `json:"checks,omitempty"`
}

func (h *HealthHandler) HealthCheck(c *gin.Context) {
	response := HealthResponse{
		Status:    "healthy",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Version:   "1.0.0",
		Checks: map[string]string{
			"database": "healthy",
			"redis":    "healthy",
		},
	}

	c.JSON(http.StatusOK, response)
}

func (h *HealthHandler) ReadinessCheck(c *gin.Context) {
	// In a real implementation, check if all dependencies are ready
	response := HealthResponse{
		Status:    "ready",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	c.JSON(http.StatusOK, response)
}

func (h *HealthHandler) LivenessCheck(c *gin.Context) {
	// Simple liveness check
	response := HealthResponse{
		Status:    "alive",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
	}

	c.JSON(http.StatusOK, response)
}

// internal/adapters/http/handlers/analytics_handler.go
package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"payment-service/internal/core/domain"
	"payment-service/internal/core/ports"
	"payment-service/pkg/logger"
)

type AnalyticsHandler struct {
	analyticsService ports.AnalyticsService
	fraudService     ports.FraudService
	auditService     ports.AuditService
	logger           logger.Logger
}

func NewAnalyticsHandler(
	analyticsService ports.AnalyticsService,
	fraudService ports.FraudService,
	auditService ports.AuditService,
	logger logger.Logger,
) *AnalyticsHandler {
	return &AnalyticsHandler{
		analyticsService: analyticsService,
		fraudService:     fraudService,
		auditService:     auditService,
		logger:           logger,
	}
}

func (h *AnalyticsHandler) GetPaymentMetrics(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	clientID := ctx.Value("client_id").(string)

	// Parse query parameters
	startTime, err := time.Parse(time.RFC3339, r.URL.Query().Get("start_time"))
	if err != nil {
		h.respondError(w, "INVALID_START_TIME", "Invalid start time format", http.StatusBadRequest)
		return
	}

	endTime, err := time.Parse(time.RFC3339, r.URL.Query().Get("end_time"))
	if err != nil {
		h.respondError(w, "INVALID_END_TIME", "Invalid end time format", http.StatusBadRequest)
		return
	}

	granularity := r.URL.Query().Get("granularity")
	if granularity == "" {
		granularity = "day"
	}

	req := ports.MetricsRequest{
		ClientID:    clientID,
		StartTime:   startTime,
		EndTime:     endTime,
		Granularity: granularity,
	}

	metrics, err := h.analyticsService.GetPaymentMetrics(ctx, req)
	if err != nil {
		h.logger.Error("Failed to get payment metrics", map[string]interface{}{
			"client_id": clientID,
			"error":     err.Error(),
		})
		h.respondError(w, "METRICS_ERROR", "Failed to retrieve metrics", http.StatusInternalServerError)
		return
	}

	// Log analytics access
	h.auditService.Log(ctx, &domain.AuditLog{
		EntityType: "analytics",
		EntityID:   "payment_metrics",
		Action:     domain.AuditActionView,
		ClientID:   clientID,
		IPAddress:  r.RemoteAddr,
		UserAgent:  r.UserAgent(),
	})

	h.respondJSON(w, http.StatusOK, map[string]interface{}{
		"metrics": metrics,
		"period": map[string]interface{}{
			"start":       startTime,
			"end":         endTime,
			"granularity": granularity,
		},
	})
}

func (h *AnalyticsHandler) GetRealTimeStats(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	clientID := ctx.Value("client_id").(string)

	stats, err := h.analyticsService.GetRealTimeStats(ctx, clientID)
	if err != nil {
		h.logger.Error("Failed to get real-time stats", map[string]interface{}{
			"client_id": clientID,
			"error":     err.Error(),
		})
		h.respondError(w, "STATS_ERROR", "Failed to retrieve real-time stats", http.StatusInternalServerError)
		return
	}

	h.respondJSON(w, http.StatusOK, stats)
}

func (h *AnalyticsHandler) GenerateReport(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	clientID := ctx.Value("client_id").(string)

	var reqBody struct {
		StartTime time.Time `json:"start_time"`
		EndTime   time.Time `json:"end_time"`
		Format    string    `json:"format"`
		Sections  []string  `json:"sections"`
		Email     string    `json:"email,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&reqBody); err != nil {
		h.respondError(w, "INVALID_JSON", "Invalid JSON format", http.StatusBadRequest)
		return
	}

	reportReq := ports.ReportRequest{
		ClientID:  clientID,
		StartTime: reqBody.StartTime,
		EndTime:   reqBody.EndTime,
		Format:    reqBody.Format,
		Sections:  reqBody.Sections,
		Email:     reqBody.Email,
	}

	report, err := h.analyticsService.GenerateReport(ctx, reportReq)
	if err != nil {
		h.logger.Error("Failed to generate report", map[string]interface{}{
			"client_id": clientID,
			"error":     err.Error(),
		})
		h.respondError(w, "REPORT_ERROR", "Failed to generate report", http.StatusInternalServerError)
		return
	}

	h.respondJSON(w, http.StatusAccepted, report)
}

func (h *AnalyticsHandler) GetFraudStats(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	clientID := ctx.Value("client_id").(string)

	periodStr := r.URL.Query().Get("period")
	period, err := time.ParseDuration(periodStr)
	if err != nil {
		period = 24 * time.Hour // Default to 24 hours
	}

	stats, err := h.fraudService.GetFraudStats(ctx, clientID, period)
	if err != nil {
		h.logger.Error("Failed to get fraud stats", map[string]interface{}{
			"client_id": clientID,
			"error":     err.Error(),
		})
		h.respondError(w, "FRAUD_STATS_ERROR", "Failed to retrieve fraud statistics", http.StatusInternalServerError)
		return
	}

	h.respondJSON(w, http.StatusOK, stats)
}

func (h *AnalyticsHandler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *AnalyticsHandler) respondError(w http.ResponseWriter, code, message string, status int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"error": map[string]interface{}{
			"code":    code,
			"message": message,
		},
	})
}

package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/freightdev/email-service/internal/services"
)

type EmailHandler struct {
	emailService *services.EmailService
}

func NewEmailHandler(emailService *services.EmailService) *EmailHandler {
	return &EmailHandler{
		emailService: emailService,
	}
}

// Health check
func (h *EmailHandler) Health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Email Service: ONLINE"))
}

// Send approval request
type ApprovalRequest struct {
	ApprovalID     string `json:"approval_id"`
	Action         string `json:"action"`
	RiskLevel      string `json:"risk_level"`
	Details        string `json:"details"`
	Recommendation string `json:"recommendation"`
}

func (h *EmailHandler) SendApproval(w http.ResponseWriter, r *http.Request) {
	var req ApprovalRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	err := h.emailService.SendApprovalRequest(
		req.ApprovalID,
		req.Action,
		req.RiskLevel,
		req.Details,
		req.Recommendation,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Approval email sent",
	})
}

// Send daily digest
type DigestRequest struct {
	Date         string                     `json:"date"`
	Summary      string                     `json:"summary"`
	FreightRates *services.FreightRates     `json:"freight_rates,omitempty"`
	NewsCount    int                        `json:"news_count"`
	RegCount     int                        `json:"regulation_count"`
}

func (h *EmailHandler) SendDigest(w http.ResponseWriter, r *http.Request) {
	var req DigestRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	err := h.emailService.SendDailyDigest(
		req.Date,
		req.Summary,
		req.FreightRates,
		req.NewsCount,
		req.RegCount,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Daily digest sent",
	})
}

// Send notification
type NotificationRequest struct {
	Title    string `json:"title"`
	Message  string `json:"message"`
	Priority string `json:"priority"` // low, normal, high, critical
}

func (h *EmailHandler) SendNotification(w http.ResponseWriter, r *http.Request) {
	var req NotificationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	priority := services.PriorityNormal
	switch req.Priority {
	case "low":
		priority = services.PriorityLow
	case "high":
		priority = services.PriorityHigh
	case "critical":
		priority = services.PriorityCritical
	}

	err := h.emailService.SendNotification(req.Title, req.Message, priority)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Notification sent",
	})
}

// Send status report
type StatusRequest struct {
	AgentsOnline     []string `json:"agents_online"`
	AgentsOffline    []string `json:"agents_offline"`
	RecentDecisions  []string `json:"recent_decisions"`
	PendingApprovals int      `json:"pending_approvals"`
}

func (h *EmailHandler) SendStatus(w http.ResponseWriter, r *http.Request) {
	var req StatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	err := h.emailService.SendStatusReport(
		req.AgentsOnline,
		req.AgentsOffline,
		req.RecentDecisions,
		req.PendingApprovals,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Status report sent",
	})
}

// Send alert
type AlertRequest struct {
	Error   string `json:"error"`
	Details string `json:"details"`
}

func (h *EmailHandler) SendAlert(w http.ResponseWriter, r *http.Request) {
	var req AlertRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	err := h.emailService.SendAlert(req.Error, req.Details)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Alert sent",
	})
}

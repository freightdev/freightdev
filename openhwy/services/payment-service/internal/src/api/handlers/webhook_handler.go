// internal/adapters/http/handlers/webhook_handler.go
package handlers

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"time"

	"payment-service/internal/core/ports"
	"payment-service/pkg/logger"
)

type WebhookHandler struct {
	paymentService ports.PaymentService
	webhookSecret  string
	logger         logger.Logger
}

func NewWebhookHandler(
	paymentService ports.PaymentService,
	webhookSecret string,
	logger logger.Logger,
) *WebhookHandler {
	return &WebhookHandler{
		paymentService: paymentService,
		webhookSecret:  webhookSecret,
		logger:         logger,
	}
}

type WebhookEvent struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"`
	Data      map[string]interface{} `json:"data"`
	CreatedAt time.Time              `json:"created_at"`
}

func (h *WebhookHandler) HandleStripeWebhook(w http.ResponseWriter, r *http.Request) {
	payload, err := io.ReadAll(r.Body)
	if err != nil {
		h.logger.Error("Failed to read webhook payload", map[string]interface{}{
			"error": err.Error(),
		})
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	// Verify signature
	if !h.verifyStripeSignature(payload, r.Header.Get("Stripe-Signature")) {
		h.logger.Warn("Invalid webhook signature", map[string]interface{}{
			"remote_addr": r.RemoteAddr,
		})
		w.WriteHeader(http.StatusUnauthorized)
		return
	}

	var event WebhookEvent
	if err := json.Unmarshal(payload, &event); err != nil {
		h.logger.Error("Failed to unmarshal webhook event", map[string]interface{}{
			"error": err.Error(),
		})
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	h.logger.Info("Processing webhook event", map[string]interface{}{
		"event_id":   event.ID,
		"event_type": event.Type,
	})

	if err := h.processWebhookEvent(r.Context(), &event); err != nil {
		h.logger.Error("Failed to process webhook event", map[string]interface{}{
			"event_id": event.ID,
			"error":    err.Error(),
		})
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "success"})
}

func (h *WebhookHandler) HandlePayPalWebhook(w http.ResponseWriter, r *http.Request) {
	// Similar implementation for PayPal webhooks
	payload, err := io.ReadAll(r.Body)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	var event WebhookEvent
	if err := json.Unmarshal(payload, &event); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	h.logger.Info("Processing PayPal webhook event", map[string]interface{}{
		"event_id":   event.ID,
		"event_type": event.Type,
	})

	if err := h.processWebhookEvent(r.Context(), &event); err != nil {
		h.logger.Error("Failed to process PayPal webhook", map[string]interface{}{
			"event_id": event.ID,
			"error":    err.Error(),
		})
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
}

func (h *WebhookHandler) verifyStripeSignature(payload []byte, signature string) bool {
	if h.webhookSecret == "" {
		return true // Skip verification if no secret configured
	}

	mac := hmac.New(sha256.New, []byte(h.webhookSecret))
	mac.Write(payload)
	expectedMAC := hex.EncodeToString(mac.Sum(nil))

	// Extract signature from header (format: t=timestamp,v1=signature)
	parts := make(map[string]string)
	for _, part := range strings.Split(signature, ",") {
		kv := strings.SplitN(part, "=", 2)
		if len(kv) == 2 {
			parts[kv[0]] = kv[1]
		}
	}

	providedMAC := parts["v1"]
	return hmac.Equal([]byte(expectedMAC), []byte(providedMAC))
}

func (h *WebhookHandler) processWebhookEvent(ctx context.Context, event *WebhookEvent) error {
	switch event.Type {
	case "payment_intent.succeeded":
		return h.handlePaymentSucceeded(ctx, event)
	case "payment_intent.payment_failed":
		return h.handlePaymentFailed(ctx, event)
	case "charge.dispute.created":
		return h.handleDisputeCreated(ctx, event)
	default:
		h.logger.Info("Unhandled webhook event type", map[string]interface{}{
			"event_type": event.Type,
		})
		return nil
	}
}

func (h *WebhookHandler) handlePaymentSucceeded(ctx context.Context, event *WebhookEvent) error {
	// Extract payment intent ID and update payment status
	// Implementation would depend on how you store processor references
	return nil
}

func (h *WebhookHandler) handlePaymentFailed(ctx context.Context, event *WebhookEvent) error {
	// Handle payment failure
	return nil
}

func (h *WebhookHandler) handleDisputeCreated(ctx context.Context, event *WebhookEvent) error {
	// Handle chargeback/dispute creation
	return nil
}

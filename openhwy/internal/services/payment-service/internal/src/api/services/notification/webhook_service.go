// internal/adapters/external/notification/webhook_service.go
package notification

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"payment-service/internal/core/domain"
	"payment-service/internal/core/ports"
	"payment-service/pkg/logger"
)

type WebhookNotificationService struct {
	httpClient *http.Client
	logger     logger.Logger
	webhookURL string
}

func NewWebhookNotificationService(webhookURL string, logger logger.Logger) ports.NotificationService {
	return &WebhookNotificationService{
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
		logger:     logger,
		webhookURL: webhookURL,
	}
}

type WebhookPayload struct {
	Event     string                 `json:"event"`
	Payment   *domain.Payment        `json:"payment"`
	Timestamp int64                  `json:"timestamp"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

func (w *WebhookNotificationService) NotifyPaymentCreated(ctx context.Context, payment *domain.Payment) error {
	return w.sendWebhook(ctx, "payment.created", payment)
}

func (w *WebhookNotificationService) NotifyPaymentProcessed(ctx context.Context, payment *domain.Payment) error {
	return w.sendWebhook(ctx, "payment.processed", payment)
}

func (w *WebhookNotificationService) NotifyPaymentFailed(ctx context.Context, payment *domain.Payment) error {
	return w.sendWebhook(ctx, "payment.failed", payment)
}

func (w *WebhookNotificationService) NotifyPaymentRefunded(ctx context.Context, payment *domain.Payment) error {
	return w.sendWebhook(ctx, "payment.refunded", payment)
}

func (w *WebhookNotificationService) sendWebhook(ctx context.Context, event string, payment *domain.Payment) error {
	if w.webhookURL == "" {
		w.logger.Debug("Webhook URL not configured, skipping notification", map[string]interface{}{
			"event":      event,
			"payment_id": payment.ID.String(),
		})
		return nil
	}

	payload := WebhookPayload{
		Event:     event,
		Payment:   payment,
		Timestamp: time.Now().Unix(),
		Metadata: map[string]interface{}{
			"service": "payment-service",
			"version": "1.0.0",
		},
	}

	requestBody, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal webhook payload: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", w.webhookURL, bytes.NewReader(requestBody))
	if err != nil {
		return fmt.Errorf("failed to create webhook request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Event-Type", event)
	req.Header.Set("X-Payment-ID", payment.ID.String())

	resp, err := w.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send webhook: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return fmt.Errorf("webhook returned error status: %d", resp.StatusCode)
	}

	w.logger.Info("Webhook sent successfully", map[string]interface{}{
		"event":       event,
		"payment_id":  payment.ID.String(),
		"status_code": resp.StatusCode,
		"webhook_url": w.webhookURL,
	})

	return nil
}

// internal/core/ports/notification_service.go
package ports

import (
	"context"
	"payment-service/internal/core/domain"
)

type PaymentNotification struct {
	Event     string                 `json:"event"`
	Payment   *domain.Payment        `json:"payment"`
	Timestamp int64                  `json:"timestamp"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

type NotificationService interface {
	NotifyPaymentCreated(ctx context.Context, payment *domain.Payment) error
	NotifyPaymentProcessed(ctx context.Context, payment *domain.Payment) error
	NotifyPaymentFailed(ctx context.Context, payment *domain.Payment) error
	NotifyPaymentRefunded(ctx context.Context, payment *domain.Payment) error
}

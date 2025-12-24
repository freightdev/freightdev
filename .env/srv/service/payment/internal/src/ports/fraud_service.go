// internal/core/ports/fraud_service.go
package ports

import (
	"context"
	"payment-service/internal/core/domain"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type FraudCheckRequest struct {
	Payment   *domain.Payment        `json:"payment"`
	IPAddress string                 `json:"ip_address"`
	DeviceID  string                 `json:"device_id,omitempty"`
	UserAgent string                 `json:"user_agent,omitempty"`
	Metadata  map[string]interface{} `json:"metadata,omitempty"`
}

type FraudService interface {
	CheckPayment(ctx context.Context, req FraudCheckRequest) (*domain.FraudCheck, error)
	GetFraudCheck(ctx context.Context, paymentID uuid.UUID) (*domain.FraudCheck, error)
	ReviewFraudCheck(ctx context.Context, fraudCheckID uuid.UUID, reviewerID, notes string) error
	GetFraudStats(ctx context.Context, clientID string, period time.Duration) (*FraudStats, error)
}

type FraudStats struct {
	TotalChecks    int64           `json:"total_checks"`
	BlockedCount   int64           `json:"blocked_count"`
	ReviewCount    int64           `json:"review_count"`
	FalsePositives int64           `json:"false_positives"`
	BlockRate      decimal.Decimal `json:"block_rate"`
}

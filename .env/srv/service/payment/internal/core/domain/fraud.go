// internal/core/domain/fraud.go
package domain

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type FraudRiskLevel string
type FraudReason string

const (
	FraudRiskLow     FraudRiskLevel = "low"
	FraudRiskMedium  FraudRiskLevel = "medium"
	FraudRiskHigh    FraudRiskLevel = "high"
	FraudRiskBlocked FraudRiskLevel = "blocked"
)

const (
	FraudReasonVelocity  FraudReason = "velocity_check"
	FraudReasonAmount    FraudReason = "suspicious_amount"
	FraudReasonLocation  FraudReason = "location_mismatch"
	FraudReasonDevice    FraudReason = "suspicious_device"
	FraudReasonBehavior  FraudReason = "unusual_behavior"
	FraudReasonBlacklist FraudReason = "blacklisted"
	FraudReasonMLModel   FraudReason = "ml_model_flag"
)

type FraudCheck struct {
	ID          uuid.UUID              `json:"id"`
	PaymentID   uuid.UUID              `json:"payment_id"`
	RiskLevel   FraudRiskLevel         `json:"risk_level"`
	RiskScore   decimal.Decimal        `json:"risk_score"`
	Reasons     []FraudReason          `json:"reasons"`
	Details     map[string]interface{} `json:"details"`
	IPAddress   string                 `json:"ip_address"`
	DeviceID    string                 `json:"device_id,omitempty"`
	Location    *GeoLocation           `json:"location,omitempty"`
	CreatedAt   time.Time              `json:"created_at"`
	ReviewedAt  *time.Time             `json:"reviewed_at,omitempty"`
	ReviewerID  string                 `json:"reviewer_id,omitempty"`
	ReviewNotes string                 `json:"review_notes,omitempty"`
}

type GeoLocation struct {
	Country   string  `json:"country"`
	Region    string  `json:"region"`
	City      string  `json:"city"`
	Latitude  float64 `json:"latitude,omitempty"`
	Longitude float64 `json:"longitude,omitempty"`
}

func NewFraudCheck(paymentID uuid.UUID, ipAddress string) *FraudCheck {
	return &FraudCheck{
		ID:        uuid.New(),
		PaymentID: paymentID,
		RiskLevel: FraudRiskLow,
		RiskScore: decimal.Zero,
		Reasons:   make([]FraudReason, 0),
		Details:   make(map[string]interface{}),
		IPAddress: ipAddress,
		CreatedAt: time.Now().UTC(),
	}
}

func (f *FraudCheck) AddReason(reason FraudReason, details map[string]interface{}) {
	f.Reasons = append(f.Reasons, reason)
	for k, v := range details {
		f.Details[string(reason)+"_"+k] = v
	}
}

func (f *FraudCheck) ShouldBlock() bool {
	return f.RiskLevel == FraudRiskBlocked || f.RiskScore.GreaterThan(decimal.NewFromFloat(0.8))
}

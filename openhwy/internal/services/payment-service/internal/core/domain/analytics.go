// internal/core/domain/analytics.go
package domain

import (
	"time"

	"github.com/shopspring/decimal"
)

type PaymentMetrics struct {
	Period        string          `json:"period"`
	TotalAmount   decimal.Decimal `json:"total_amount"`
	TotalCount    int64           `json:"total_count"`
	SuccessCount  int64           `json:"success_count"`
	FailureCount  int64           `json:"failure_count"`
	RefundCount   int64           `json:"refund_count"`
	RefundAmount  decimal.Decimal `json:"refund_amount"`
	SuccessRate   decimal.Decimal `json:"success_rate"`
	AverageAmount decimal.Decimal `json:"average_amount"`
	Currency      Currency        `json:"currency"`
	CreatedAt     time.Time       `json:"created_at"`
}

type ProcessorMetrics struct {
	ProcessorName  string          `json:"processor_name"`
	TotalAmount    decimal.Decimal `json:"total_amount"`
	TotalCount     int64           `json:"total_count"`
	SuccessRate    decimal.Decimal `json:"success_rate"`
	AverageLatency time.Duration   `json:"average_latency"`
	ErrorRate      decimal.Decimal `json:"error_rate"`
	Period         string          `json:"period"`
}

type ClientMetrics struct {
	ClientID    string          `json:"client_id"`
	TotalAmount decimal.Decimal `json:"total_amount"`
	TotalCount  int64           `json:"total_count"`
	SuccessRate decimal.Decimal `json:"success_rate"`
	RefundRate  decimal.Decimal `json:"refund_rate"`
	Period      string          `json:"period"`
}

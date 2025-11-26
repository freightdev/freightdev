// internal/core/ports/analytics_service.go
package ports

import (
	"context"
	"payment-service/internal/core/domain"
	"time"

	"github.com/shopspring/decimal"
)

type AnalyticsService interface {
	GetPaymentMetrics(ctx context.Context, req MetricsRequest) ([]*domain.PaymentMetrics, error)
	GetProcessorMetrics(ctx context.Context, req MetricsRequest) ([]*domain.ProcessorMetrics, error)
	GetClientMetrics(ctx context.Context, req MetricsRequest) ([]*domain.ClientMetrics, error)
	GenerateReport(ctx context.Context, req ReportRequest) (*PaymentReport, error)
	GetRealTimeStats(ctx context.Context, clientID string) (*RealTimeStats, error)
}

type MetricsRequest struct {
	ClientID    string               `json:"client_id"`
	StartTime   time.Time            `json:"start_time"`
	EndTime     time.Time            `json:"end_time"`
	Granularity string               `json:"granularity"` // hour, day, week, month
	Currency    domain.Currency      `json:"currency,omitempty"`
	Method      domain.PaymentMethod `json:"method,omitempty"`
}

type ReportRequest struct {
	ClientID  string    `json:"client_id"`
	StartTime time.Time `json:"start_time"`
	EndTime   time.Time `json:"end_time"`
	Format    string    `json:"format"` // csv, xlsx, pdf
	Sections  []string  `json:"sections"`
	Email     string    `json:"email,omitempty"`
}

type PaymentReport struct {
	ID          string                 `json:"id"`
	ClientID    string                 `json:"client_id"`
	Period      string                 `json:"period"`
	Summary     *ReportSummary         `json:"summary"`
	Sections    map[string]interface{} `json:"sections"`
	GeneratedAt time.Time              `json:"generated_at"`
	DownloadURL string                 `json:"download_url"`
}

type ReportSummary struct {
	TotalTransactions int64           `json:"total_transactions"`
	TotalAmount       decimal.Decimal `json:"total_amount"`
	SuccessRate       decimal.Decimal `json:"success_rate"`
	RefundRate        decimal.Decimal `json:"refund_rate"`
	TopCountries      []string        `json:"top_countries"`
	TopMethods        []string        `json:"top_methods"`
}

type RealTimeStats struct {
	ActiveSessions    int64           `json:"active_sessions"`
	TransactionsToday int64           `json:"transactions_today"`
	AmountToday       decimal.Decimal `json:"amount_today"`
	SuccessRateToday  decimal.Decimal `json:"success_rate_today"`
	LastTransaction   *time.Time      `json:"last_transaction,omitempty"`
	SystemHealth      string          `json:"system_health"`
}

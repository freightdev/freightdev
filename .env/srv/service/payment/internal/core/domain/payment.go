// internal/core/domain/payment.go
package domain

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type PaymentStatus string
type PaymentMethod string
type Currency string

const (
	PaymentStatusPending    PaymentStatus = "pending"
	PaymentStatusProcessing PaymentStatus = "processing"
	PaymentStatusCompleted  PaymentStatus = "completed"
	PaymentStatusFailed     PaymentStatus = "failed"
	PaymentStatusRefunded   PaymentStatus = "refunded"
	PaymentStatusCancelled  PaymentStatus = "cancelled"
)

const (
	PaymentMethodCard   PaymentMethod = "card"
	PaymentMethodBank   PaymentMethod = "bank_transfer"
	PaymentMethodWallet PaymentMethod = "wallet"
	PaymentMethodCrypto PaymentMethod = "crypto"
)

const (
	CurrencyUSD Currency = "USD"
	CurrencyEUR Currency = "EUR"
	CurrencyGBP Currency = "GBP"
)

type Payment struct {
	ID            uuid.UUID              `json:"id"`
	ClientID      string                 `json:"client_id"`
	MerchantID    string                 `json:"merchant_id"`
	OrderID       string                 `json:"order_id"`
	Amount        decimal.Decimal        `json:"amount"`
	Currency      Currency               `json:"currency"`
	Status        PaymentStatus          `json:"status"`
	Method        PaymentMethod          `json:"method"`
	Description   string                 `json:"description"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
	ProcessorRef  string                 `json:"processor_ref,omitempty"`
	FailureReason string                 `json:"failure_reason,omitempty"`
	CreatedAt     time.Time              `json:"created_at"`
	UpdatedAt     time.Time              `json:"updated_at"`
	ProcessedAt   *time.Time             `json:"processed_at,omitempty"`
}

func NewPayment(clientID, merchantID, orderID string, amount decimal.Decimal, currency Currency, method PaymentMethod, description string) *Payment {
	return &Payment{
		ID:          uuid.New(),
		ClientID:    clientID,
		MerchantID:  merchantID,
		OrderID:     orderID,
		Amount:      amount,
		Currency:    currency,
		Status:      PaymentStatusPending,
		Method:      method,
		Description: description,
		Metadata:    make(map[string]interface{}),
		CreatedAt:   time.Now().UTC(),
		UpdatedAt:   time.Now().UTC(),
	}
}

func (p *Payment) MarkProcessing() {
	p.Status = PaymentStatusProcessing
	p.UpdatedAt = time.Now().UTC()
}

func (p *Payment) MarkCompleted(processorRef string) {
	p.Status = PaymentStatusCompleted
	p.ProcessorRef = processorRef
	now := time.Now().UTC()
	p.ProcessedAt = &now
	p.UpdatedAt = now
}

func (p *Payment) MarkFailed(reason string) {
	p.Status = PaymentStatusFailed
	p.FailureReason = reason
	p.UpdatedAt = time.Now().UTC()
}

func (p *Payment) CanBeProcessed() bool {
	return p.Status == PaymentStatusPending
}

func (p *Payment) CanBeRefunded() bool {
	return p.Status == PaymentStatusCompleted
}

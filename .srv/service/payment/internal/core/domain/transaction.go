// internal/core/domain/transaction.go
package domain

import (
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type TransactionType string
type TransactionStatus string

const (
	TransactionTypePayment TransactionType = "payment"
	TransactionTypeRefund  TransactionType = "refund"
	TransactionTypeVoid    TransactionType = "void"
)

const (
	TransactionStatusPending   TransactionStatus = "pending"
	TransactionStatusSucceeded TransactionStatus = "succeeded"
	TransactionStatusFailed    TransactionStatus = "failed"
)

type Transaction struct {
	ID           uuid.UUID              `json:"id"`
	PaymentID    uuid.UUID              `json:"payment_id"`
	Type         TransactionType        `json:"type"`
	Status       TransactionStatus      `json:"status"`
	Amount       decimal.Decimal        `json:"amount"`
	Currency     Currency               `json:"currency"`
	ProcessorID  string                 `json:"processor_id"`
	ProcessorRef string                 `json:"processor_ref,omitempty"`
	ErrorCode    string                 `json:"error_code,omitempty"`
	ErrorMessage string                 `json:"error_message,omitempty"`
	Metadata     map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt    time.Time              `json:"created_at"`
	UpdatedAt    time.Time              `json:"updated_at"`
	CompletedAt  *time.Time             `json:"completed_at,omitempty"`
}

func NewTransaction(paymentID uuid.UUID, txType TransactionType, amount decimal.Decimal, currency Currency, processorID string) *Transaction {
	return &Transaction{
		ID:          uuid.New(),
		PaymentID:   paymentID,
		Type:        txType,
		Status:      TransactionStatusPending,
		Amount:      amount,
		Currency:    currency,
		ProcessorID: processorID,
		Metadata:    make(map[string]interface{}),
		CreatedAt:   time.Now().UTC(),
		UpdatedAt:   time.Now().UTC(),
	}
}

func (t *Transaction) MarkSucceeded(processorRef string) {
	t.Status = TransactionStatusSucceeded
	t.ProcessorRef = processorRef
	now := time.Now().UTC()
	t.CompletedAt = &now
	t.UpdatedAt = now
}

func (t *Transaction) MarkFailed(errorCode, errorMessage string) {
	t.Status = TransactionStatusFailed
	t.ErrorCode = errorCode
	t.ErrorMessage = errorMessage
	now := time.Now().UTC()
	t.CompletedAt = &now
	t.UpdatedAt = now
}

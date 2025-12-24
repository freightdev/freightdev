// internal/core/ports/payment_repository.go
package ports

import (
	"context"
	"payment-service/internal/core/domain"

	"github.com/google/uuid"
)

type PaymentRepository interface {
	Create(ctx context.Context, payment *domain.Payment) error
	Update(ctx context.Context, payment *domain.Payment) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.Payment, error)
	GetByOrderID(ctx context.Context, clientID, orderID string) (*domain.Payment, error)
	List(ctx context.Context, clientID string, limit, offset int) ([]*domain.Payment, error)
	Delete(ctx context.Context, id uuid.UUID) error
}

type TransactionRepository interface {
	Create(ctx context.Context, transaction *domain.Transaction) error
	Update(ctx context.Context, transaction *domain.Transaction) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.Transaction, error)
	GetByPaymentID(ctx context.Context, paymentID uuid.UUID) ([]*domain.Transaction, error)
	List(ctx context.Context, paymentID uuid.UUID, limit, offset int) ([]*domain.Transaction, error)
}

// internal/adapters/repository/postgres/payment_repository.go
package postgres

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"payment-service/internal/core/domain"
	"payment-service/internal/core/ports"

	"github.com/google/uuid"
	"github.com/lib/pq"
)

type PaymentRepository struct {
	db *sql.DB
}

func NewPaymentRepository(db *sql.DB) ports.PaymentRepository {
	return &PaymentRepository{db: db}
}

func (r *PaymentRepository) Create(ctx context.Context, payment *domain.Payment) error {
	query := `
        INSERT INTO payments (
            id, client_id, merchant_id, order_id, amount, currency, status, method,
            description, metadata, processor_ref, failure_reason, created_at, updated_at, processed_at
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
        )`

	metadataJSON, err := json.Marshal(payment.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	_, err = r.db.ExecContext(ctx, query,
		payment.ID,
		payment.ClientID,
		payment.MerchantID,
		payment.OrderID,
		payment.Amount,
		string(payment.Currency),
		string(payment.Status),
		string(payment.Method),
		payment.Description,
		metadataJSON,
		nullString(payment.ProcessorRef),
		nullString(payment.FailureReason),
		payment.CreatedAt,
		payment.UpdatedAt,
		payment.ProcessedAt,
	)

	if err != nil {
		if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" {
			return fmt.Errorf("payment with order_id already exists: %w", err)
		}
		return fmt.Errorf("failed to create payment: %w", err)
	}

	return nil
}

func (r *PaymentRepository) Update(ctx context.Context, payment *domain.Payment) error {
	query := `
        UPDATE payments
        SET status = $2, metadata = $3, processor_ref = $4, failure_reason = $5,
            updated_at = $6, processed_at = $7
        WHERE id = $1`

	metadataJSON, err := json.Marshal(payment.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	result, err := r.db.ExecContext(ctx, query,
		payment.ID,
		string(payment.Status),
		metadataJSON,
		nullString(payment.ProcessorRef),
		nullString(payment.FailureReason),
		payment.UpdatedAt,
		payment.ProcessedAt,
	)

	if err != nil {
		return fmt.Errorf("failed to update payment: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("payment not found")
	}

	return nil
}

func (r *PaymentRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.Payment, error) {
	query := `
        SELECT id, client_id, merchant_id, order_id, amount, currency, status, method,
               description, metadata, processor_ref, failure_reason, created_at, updated_at, processed_at
        FROM payments
        WHERE id = $1`

	return r.scanPayment(ctx, query, id)
}

func (r *PaymentRepository) GetByOrderID(ctx context.Context, clientID, orderID string) (*domain.Payment, error) {
	query := `
        SELECT id, client_id, merchant_id, order_id, amount, currency, status, method,
               description, metadata, processor_ref, failure_reason, created_at, updated_at, processed_at
        FROM payments
        WHERE client_id = $1 AND order_id = $2`

	return r.scanPayment(ctx, query, clientID, orderID)
}

func (r *PaymentRepository) List(ctx context.Context, clientID string, limit, offset int) ([]*domain.Payment, error) {
	query := `
        SELECT id, client_id, merchant_id, order_id, amount, currency, status, method,
               description, metadata, processor_ref, failure_reason, created_at, updated_at, processed_at
        FROM payments
        WHERE client_id = $1
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3`

	rows, err := r.db.QueryContext(ctx, query, clientID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to list payments: %w", err)
	}
	defer rows.Close()

	var payments []*domain.Payment
	for rows.Next() {
		payment, err := r.scanPaymentFromRow(rows)
		if err != nil {
			return nil, err
		}
		payments = append(payments, payment)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating payment rows: %w", err)
	}

	return payments, nil
}

func (r *PaymentRepository) Delete(ctx context.Context, id uuid.UUID) error {
	query := `DELETE FROM payments WHERE id = $1`

	result, err := r.db.ExecContext(ctx, query, id)
	if err != nil {
		return fmt.Errorf("failed to delete payment: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("payment not found")
	}

	return nil
}

func (r *PaymentRepository) scanPayment(ctx context.Context, query string, args ...interface{}) (*domain.Payment, error) {
	row := r.db.QueryRowContext(ctx, query, args...)
	return r.scanPaymentFromRow(row)
}

func (r *PaymentRepository) scanPaymentFromRow(scanner interface {
	Scan(dest ...interface{}) error
}) (*domain.Payment, error) {
	var payment domain.Payment
	var currency, status, method string
	var metadataJSON []byte
	var processorRef, failureReason sql.NullString
	var processedAt sql.NullTime

	err := scanner.Scan(
		&payment.ID,
		&payment.ClientID,
		&payment.MerchantID,
		&payment.OrderID,
		&payment.Amount,
		&currency,
		&status,
		&method,
		&payment.Description,
		&metadataJSON,
		&processorRef,
		&failureReason,
		&payment.CreatedAt,
		&payment.UpdatedAt,
		&processedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("payment not found")
		}
		return nil, fmt.Errorf("failed to scan payment: %w", err)
	}

	payment.Currency = domain.Currency(currency)
	payment.Status = domain.PaymentStatus(status)
	payment.Method = domain.PaymentMethod(method)
	payment.ProcessorRef = processorRef.String
	payment.FailureReason = failureReason.String

	if processedAt.Valid {
		payment.ProcessedAt = &processedAt.Time
	}

	if err := json.Unmarshal(metadataJSON, &payment.Metadata); err != nil {
		payment.Metadata = make(map[string]interface{})
	}

	return &payment, nil
}

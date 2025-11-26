// internal/adapters/repository/postgres/transaction_repository.go
package postgres

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	"payment-service/internal/core/domain"
	"payment-service/internal/core/ports"

	"github.com/google/uuid"
)

type TransactionRepository struct {
	db *sql.DB
}

func NewTransactionRepository(db *sql.DB) ports.TransactionRepository {
	return &TransactionRepository{db: db}
}

func (r *TransactionRepository) Create(ctx context.Context, transaction *domain.Transaction) error {
	query := `
        INSERT INTO transactions (
            id, payment_id, type, status, amount, currency, processor_id,
            processor_ref, error_code, error_message, metadata, created_at, updated_at, completed_at
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
        )`

	metadataJSON, err := json.Marshal(transaction.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	_, err = r.db.ExecContext(ctx, query,
		transaction.ID,
		transaction.PaymentID,
		string(transaction.Type),
		string(transaction.Status),
		transaction.Amount,
		string(transaction.Currency),
		transaction.ProcessorID,
		nullString(transaction.ProcessorRef),
		nullString(transaction.ErrorCode),
		nullString(transaction.ErrorMessage),
		metadataJSON,
		transaction.CreatedAt,
		transaction.UpdatedAt,
		transaction.CompletedAt,
	)

	if err != nil {
		return fmt.Errorf("failed to create transaction: %w", err)
	}

	return nil
}

func (r *TransactionRepository) Update(ctx context.Context, transaction *domain.Transaction) error {
	query := `
        UPDATE transactions
        SET status = $2, processor_ref = $3, error_code = $4, error_message = $5,
            metadata = $6, updated_at = $7, completed_at = $8
        WHERE id = $1`

	metadataJSON, err := json.Marshal(transaction.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	result, err := r.db.ExecContext(ctx, query,
		transaction.ID,
		string(transaction.Status),
		nullString(transaction.ProcessorRef),
		nullString(transaction.ErrorCode),
		nullString(transaction.ErrorMessage),
		metadataJSON,
		transaction.UpdatedAt,
		transaction.CompletedAt,
	)

	if err != nil {
		return fmt.Errorf("failed to update transaction: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("failed to check rows affected: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("transaction not found")
	}

	return nil
}

func (r *TransactionRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.Transaction, error) {
	query := `
        SELECT id, payment_id, type, status, amount, currency, processor_id,
               processor_ref, error_code, error_message, metadata, created_at, updated_at, completed_at
        FROM transactions
        WHERE id = $1`

	return r.scanTransaction(ctx, query, id)
}

func (r *TransactionRepository) GetByPaymentID(ctx context.Context, paymentID uuid.UUID) ([]*domain.Transaction, error) {
	query := `
        SELECT id, payment_id, type, status, amount, currency, processor_id,
               processor_ref, error_code, error_message, metadata, created_at, updated_at, completed_at
        FROM transactions
        WHERE payment_id = $1
        ORDER BY created_at DESC`

	rows, err := r.db.QueryContext(ctx, query, paymentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get transactions by payment ID: %w", err)
	}
	defer rows.Close()

	var transactions []*domain.Transaction
	for rows.Next() {
		transaction, err := r.scanTransactionFromRow(rows)
		if err != nil {
			return nil, err
		}
		transactions = append(transactions, transaction)
	}

	return transactions, nil
}

func (r *TransactionRepository) List(ctx context.Context, paymentID uuid.UUID, limit, offset int) ([]*domain.Transaction, error) {
	query := `
        SELECT id, payment_id, type, status, amount, currency, processor_id,
               processor_ref, error_code, error_message, metadata, created_at, updated_at, completed_at
        FROM transactions
        WHERE payment_id = $1
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3`

	rows, err := r.db.QueryContext(ctx, query, paymentID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to list transactions: %w", err)
	}
	defer rows.Close()

	var transactions []*domain.Transaction
	for rows.Next() {
		transaction, err := r.scanTransactionFromRow(rows)
		if err != nil {
			return nil, err
		}
		transactions = append(transactions, transaction)
	}

	return transactions, nil
}

func (r *TransactionRepository) scanTransaction(ctx context.Context, query string, args ...interface{}) (*domain.Transaction, error) {
	row := r.db.QueryRowContext(ctx, query, args...)
	return r.scanTransactionFromRow(row)
}

func (r *TransactionRepository) scanTransactionFromRow(scanner interface {
	Scan(dest ...interface{}) error
}) (*domain.Transaction, error) {
	var transaction domain.Transaction
	var txType, status, currency string
	var metadataJSON []byte
	var processorRef, errorCode, errorMessage sql.NullString
	var completedAt sql.NullTime

	err := scanner.Scan(
		&transaction.ID,
		&transaction.PaymentID,
		&txType,
		&status,
		&transaction.Amount,
		&currency,
		&transaction.ProcessorID,
		&processorRef,
		&errorCode,
		&errorMessage,
		&metadataJSON,
		&transaction.CreatedAt,
		&transaction.UpdatedAt,
		&completedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("transaction not found")
		}
		return nil, fmt.Errorf("failed to scan transaction: %w", err)
	}

	transaction.Type = domain.TransactionType(txType)
	transaction.Status = domain.TransactionStatus(status)
	transaction.Currency = domain.Currency(currency)
	transaction.ProcessorRef = processorRef.String
	transaction.ErrorCode = errorCode.String
	transaction.ErrorMessage = errorMessage.String

	if completedAt.Valid {
		transaction.CompletedAt = &completedAt.Time
	}

	if err := json.Unmarshal(metadataJSON, &transaction.Metadata); err != nil {
		transaction.Metadata = make(map[string]interface{})
	}

	return &transaction, nil
}

func nullString(s string) sql.NullString {
	if s == "" {
		return sql.NullString{}
	}
	return sql.NullString{String: s, Valid: true}
}

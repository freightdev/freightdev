// internal/core/services/payment_service.go
package services

import (
	"context"
	"fmt"
	"time"

	"payment-service/internal/core/domain"
	"payment-service/internal/core/ports"
	"payment-service/pkg/logger"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

type PaymentServiceImpl struct {
	paymentRepo     ports.PaymentRepository
	transactionRepo ports.TransactionRepository
	processors      map[string]ports.PaymentProcessor
	notificationSvc ports.NotificationService
	logger          logger.Logger
}

func NewPaymentService(
	paymentRepo ports.PaymentRepository,
	transactionRepo ports.TransactionRepository,
	processors map[string]ports.PaymentProcessor,
	notificationSvc ports.NotificationService,
	logger logger.Logger,
) ports.PaymentService {
	return &PaymentServiceImpl{
		paymentRepo:     paymentRepo,
		transactionRepo: transactionRepo,
		processors:      processors,
		notificationSvc: notificationSvc,
		logger:          logger,
	}
}

func (s *PaymentServiceImpl) CreatePayment(ctx context.Context, req ports.CreatePaymentRequest) (*domain.Payment, error) {
	correlationID := s.getCorrelationID(ctx)
	s.logger.Info("Creating payment", map[string]interface{}{
		"correlation_id": correlationID,
		"client_id":      req.ClientID,
		"merchant_id":    req.MerchantID,
		"order_id":       req.OrderID,
		"amount":         req.Amount.String(),
		"currency":       string(req.Currency),
		"method":         string(req.Method),
	})

	// Validate business rules
	if err := s.validateCreatePaymentRequest(req); err != nil {
		s.logger.Error("Payment validation failed", map[string]interface{}{
			"correlation_id": correlationID,
			"error":          err.Error(),
		})
		return nil, err
	}

	// Check for duplicate order
	existingPayment, err := s.paymentRepo.GetByOrderID(ctx, req.ClientID, req.OrderID)
	if err == nil && existingPayment != nil {
		s.logger.Warn("Duplicate payment creation attempt", map[string]interface{}{
			"correlation_id":      correlationID,
			"existing_payment_id": existingPayment.ID.String(),
		})
		return existingPayment, nil
	}

	// Create payment entity
	payment := domain.NewPayment(
		req.ClientID,
		req.MerchantID,
		req.OrderID,
		req.Amount,
		req.Currency,
		req.Method,
		req.Description,
	)

	if req.Metadata != nil {
		payment.Metadata = req.Metadata
	}

	// Persist payment
	if err := s.paymentRepo.Create(ctx, payment); err != nil {
		s.logger.Error("Failed to create payment", map[string]interface{}{
			"correlation_id": correlationID,
			"payment_id":     payment.ID.String(),
			"error":          err.Error(),
		})
		return nil, fmt.Errorf("failed to create payment: %w", err)
	}

	// Send notification asynchronously
	go func() {
		if err := s.notificationSvc.NotifyPaymentCreated(context.Background(), payment); err != nil {
			s.logger.Error("Failed to send payment created notification", map[string]interface{}{
				"payment_id": payment.ID.String(),
				"error":      err.Error(),
			})
		}
	}()

	s.logger.Info("Payment created successfully", map[string]interface{}{
		"correlation_id": correlationID,
		"payment_id":     payment.ID.String(),
	})

	return payment, nil
}

func (s *PaymentServiceImpl) ProcessPayment(ctx context.Context, req ports.ProcessPaymentRequest) (*domain.Payment, error) {
	correlationID := s.getCorrelationID(ctx)
	s.logger.Info("Processing payment", map[string]interface{}{
		"correlation_id": correlationID,
		"payment_id":     req.PaymentID.String(),
	})

	// Get payment
	payment, err := s.paymentRepo.GetByID(ctx, req.PaymentID)
	if err != nil {
		s.logger.Error("Payment not found for processing", map[string]interface{}{
			"correlation_id": correlationID,
			"payment_id":     req.PaymentID.String(),
			"error":          err.Error(),
		})
		return nil, domain.ErrPaymentNotFound
	}

	// Validate payment can be processed
	if !payment.CanBeProcessed() {
		s.logger.Warn("Payment cannot be processed", map[string]interface{}{
			"correlation_id": correlationID,
			"payment_id":     payment.ID.String(),
			"current_status": string(payment.Status),
		})
		return nil, domain.ErrPaymentAlreadyProcessed
	}

	// Get appropriate processor
	processor, err := s.getProcessor(payment.Method, payment.Currency)
	if err != nil {
		s.logger.Error("No suitable processor found", map[string]interface{}{
			"correlation_id": correlationID,
			"payment_id":     payment.ID.String(),
			"method":         string(payment.Method),
			"currency":       string(payment.Currency),
			"error":          err.Error(),
		})
		return nil, err
	}

	// Mark payment as processing
	payment.MarkProcessing()
	if err := s.paymentRepo.Update(ctx, payment); err != nil {
		s.logger.Error("Failed to update payment status to processing", map[string]interface{}{
			"correlation_id": correlationID,
			"payment_id":     payment.ID.String(),
			"error":          err.Error(),
		})
		return nil, fmt.Errorf("failed to update payment: %w", err)
	}

	// Create transaction record
	transaction := domain.NewTransaction(
		payment.ID,
		domain.TransactionTypePayment,
		payment.Amount,
		payment.Currency,
		s.getProcessorID(processor),
	)

	if err := s.transactionRepo.Create(ctx, transaction); err != nil {
		s.logger.Error("Failed to create transaction record", map[string]interface{}{
			"correlation_id": correlationID,
			"payment_id":     payment.ID.String(),
			"transaction_id": transaction.ID.String(),
			"error":          err.Error(),
		})
		return nil, fmt.Errorf("failed to create transaction: %w", err)
	}

	// Process payment with external processor
	processReq := ports.ProcessPaymentRequest{
		Amount:         payment.Amount,
		Currency:       payment.Currency,
		Method:         payment.Method,
		PaymentDetails: req.PaymentDetails,
		Metadata:       payment.Metadata,
	}

	processResp, err := processor.ProcessPayment(ctx, processReq)
	if err != nil {
		s.logger.Error("Payment processing failed", map[string]interface{}{
			"correlation_id": correlationID,
			"payment_id":     payment.ID.String(),
			"transaction_id": transaction.ID.String(),
			"error":          err.Error(),
		})

		// Mark transaction as failed
		transaction.MarkFailed("PROCESSOR_ERROR", err.Error())
		s.transactionRepo.Update(ctx, transaction)

		// Mark payment as failed
		payment.MarkFailed(err.Error())
		s.paymentRepo.Update(ctx, payment)

		// Send notification
		go s.notificationSvc.NotifyPaymentFailed(context.Background(), payment)

		return payment, err
	}

	// Mark transaction as succeeded
	transaction.MarkSucceeded(processResp.ProcessorRef)
	if err := s.transactionRepo.Update(ctx, transaction); err != nil {
		s.logger.Error("Failed to update transaction status", map[string]interface{}{
			"correlation_id": correlationID,
			"transaction_id": transaction.ID.String(),
			"error":          err.Error(),
		})
	}

	// Mark payment as completed
	payment.MarkCompleted(processResp.ProcessorRef)
	if processResp.Metadata != nil {
		for k, v := range processResp.Metadata {
			payment.Metadata[k] = v
		}
	}

	if err := s.paymentRepo.Update(ctx, payment); err != nil {
		s.logger.Error("Failed to update payment status to completed", map[string]interface{}{
			"correlation_id": correlationID,
			"payment_id":     payment.ID.String(),
			"error":          err.Error(),
		})
		return nil, fmt.Errorf("failed to update payment: %w", err)
	}

	// Send notification
	go s.notificationSvc.NotifyPaymentProcessed(context.Background(), payment)

	s.logger.Info("Payment processed successfully", map[string]interface{}{
		"correlation_id": correlationID,
		"payment_id":     payment.ID.String(),
		"processor_ref":  processResp.ProcessorRef,
	})

	return payment, nil
}

func (s *PaymentServiceImpl) RefundPayment(ctx context.Context, req ports.RefundPaymentRequest) (*domain.Payment, error) {
	correlationID := s.getCorrelationID(ctx)
	s.logger.Info("Processing refund", map[string]interface{}{
		"correlation_id": correlationID,
		"payment_id":     req.PaymentID.String(),
		"amount":         req.Amount.String(),
	})

	// Get payment
	payment, err := s.paymentRepo.GetByID(ctx, req.PaymentID)
	if err != nil {
		return nil, domain.ErrPaymentNotFound
	}

	// Validate refund is possible
	if !payment.CanBeRefunded() {
		s.logger.Warn("Payment cannot be refunded", map[string]interface{}{
			"correlation_id": correlationID,
			"payment_id":     payment.ID.String(),
			"status":         string(payment.Status),
		})
		return nil, domain.DomainError{
			Type:    "BusinessRuleViolation",
			Code:    "REFUND_NOT_ALLOWED",
			Message: "payment cannot be refunded in current state",
		}
	}

	// Validate refund amount
	if req.Amount.GreaterThan(payment.Amount) {
		return nil, domain.DomainError{
			Type:    "ValidationError",
			Code:    "INVALID_REFUND_AMOUNT",
			Message: "refund amount exceeds payment amount",
		}
	}

	// Get processor
	processor, err := s.getProcessor(payment.Method, payment.Currency)
	if err != nil {
		return nil, err
	}

	// Create refund transaction
	refundTx := domain.NewTransaction(
		payment.ID,
		domain.TransactionTypeRefund,
		req.Amount,
		payment.Currency,
		s.getProcessorID(processor),
	)

	if err := s.transactionRepo.Create(ctx, refundTx); err != nil {
		return nil, fmt.Errorf("failed to create refund transaction: %w", err)
	}

	// Process refund with external processor
	refundReq := ports.RefundRequest{
		ProcessorRef: payment.ProcessorRef,
		Amount:       req.Amount,
		Currency:     payment.Currency,
		Reason:       req.Reason,
	}

	refundResp, err := processor.RefundPayment(ctx, refundReq)
	if err != nil {
		s.logger.Error("Refund processing failed", map[string]interface{}{
			"correlation_id": correlationID,
			"payment_id":     payment.ID.String(),
			"error":          err.Error(),
		})

		refundTx.MarkFailed("PROCESSOR_ERROR", err.Error())
		s.transactionRepo.Update(ctx, refundTx)
		return payment, err
	}

	// Update refund transaction
	refundTx.MarkSucceeded(refundResp.RefundRef)
	s.transactionRepo.Update(ctx, refundTx)

	// Update payment status
	if req.Amount.Equal(payment.Amount) {
		// Full refund
		payment.Status = domain.PaymentStatusRefunded
	}
	payment.UpdatedAt = time.Now().UTC()

	if err := s.paymentRepo.Update(ctx, payment); err != nil {
		return nil, fmt.Errorf("failed to update payment: %w", err)
	}

	// Send notification
	go s.notificationSvc.NotifyPaymentRefunded(context.Background(), payment)

	s.logger.Info("Refund processed successfully", map[string]interface{}{
		"correlation_id": correlationID,
		"payment_id":     payment.ID.String(),
		"refund_ref":     refundResp.RefundRef,
	})

	return payment, nil
}

func (s *PaymentServiceImpl) GetPayment(ctx context.Context, paymentID uuid.UUID) (*domain.Payment, error) {
	payment, err := s.paymentRepo.GetByID(ctx, paymentID)
	if err != nil {
		return nil, domain.ErrPaymentNotFound
	}
	return payment, nil
}

func (s *PaymentServiceImpl) GetPaymentByOrderID(ctx context.Context, clientID, orderID string) (*domain.Payment, error) {
	payment, err := s.paymentRepo.GetByOrderID(ctx, clientID, orderID)
	if err != nil {
		return nil, domain.ErrPaymentNotFound
	}
	return payment, nil
}

func (s *PaymentServiceImpl) ListPayments(ctx context.Context, clientID string, limit, offset int) ([]*domain.Payment, error) {
	if limit <= 0 || limit > 100 {
		limit = 50 // Default limit
	}
	if offset < 0 {
		offset = 0
	}

	return s.paymentRepo.List(ctx, clientID, limit, offset)
}

func (s *PaymentServiceImpl) CancelPayment(ctx context.Context, paymentID uuid.UUID) error {
	correlationID := s.getCorrelationID(ctx)
	s.logger.Info("Cancelling payment", map[string]interface{}{
		"correlation_id": correlationID,
		"payment_id":     paymentID.String(),
	})

	payment, err := s.paymentRepo.GetByID(ctx, paymentID)
	if err != nil {
		return domain.ErrPaymentNotFound
	}

	if payment.Status != domain.PaymentStatusPending {
		return domain.DomainError{
			Type:    "BusinessRuleViolation",
			Code:    "CANCEL_NOT_ALLOWED",
			Message: "only pending payments can be cancelled",
		}
	}

	payment.Status = domain.PaymentStatusCancelled
	payment.UpdatedAt = time.Now().UTC()

	return s.paymentRepo.Update(ctx, payment)
}

// Helper methods
func (s *PaymentServiceImpl) validateCreatePaymentRequest(req ports.CreatePaymentRequest) error {
	if req.Amount.LessThanOrEqual(decimal.Zero) {
		return domain.ErrInvalidAmount
	}

	// Validate currency support
	supportedCurrencies := map[domain.Currency]bool{
		domain.CurrencyUSD: true,
		domain.CurrencyEUR: true,
		domain.CurrencyGBP: true,
	}
	if !supportedCurrencies[req.Currency] {
		return domain.ErrUnsupportedCurrency
	}

	// Validate payment method support
	supportedMethods := map[domain.PaymentMethod]bool{
		domain.PaymentMethodCard:   true,
		domain.PaymentMethodBank:   true,
		domain.PaymentMethodWallet: true,
		domain.PaymentMethodCrypto: true,
	}
	if !supportedMethods[req.Method] {
		return domain.ErrUnsupportedPaymentMethod
	}

	return nil
}

func (s *PaymentServiceImpl) getProcessor(method domain.PaymentMethod, currency domain.Currency) (ports.PaymentProcessor, error) {
	for _, processor := range s.processors {
		if processor.SupportsMethod(method) && processor.SupportsCurrency(currency) {
			return processor, nil
		}
	}
	return nil, domain.ErrProcessorUnavailable
}

func (s *PaymentServiceImpl) getProcessorID(processor ports.PaymentProcessor) string {
	// This would typically be a more sophisticated mapping
	return fmt.Sprintf("%T", processor)
}

func (s *PaymentServiceImpl) getCorrelationID(ctx context.Context) string {
	if id := ctx.Value("correlation_id"); id != nil {
		return id.(string)
	}
	return uuid.New().String()
}

// internal/adapters/external/stripe/stripe_processor.go
package stripe

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"payment-service/internal/config"
	"payment-service/internal/core/domain"
	"payment-service/internal/core/ports"
	"payment-service/pkg/logger"

	"github.com/shopspring/decimal"
)

type StripeProcessor struct {
	config     config.ProcessorConfig
	httpClient *http.Client
	logger     logger.Logger
}

func NewStripeProcessor(config config.ProcessorConfig, logger logger.Logger) ports.PaymentProcessor {
	return &StripeProcessor{
		config: config,
		httpClient: &http.Client{
			Timeout: config.Timeout,
		},
		logger: logger,
	}
}

type StripePaymentIntent struct {
	Amount             int64             `json:"amount"`
	Currency           string            `json:"currency"`
	PaymentMethod      string            `json:"payment_method,omitempty"`
	PaymentMethodTypes []string          `json:"payment_method_types"`
	ConfirmationMethod string            `json:"confirmation_method"`
	Confirm            bool              `json:"confirm,omitempty"`
	Metadata           map[string]string `json:"metadata,omitempty"`
}

type StripePaymentIntentResponse struct {
	ID               string              `json:"id"`
	Status           string              `json:"status"`
	Amount           int64               `json:"amount"`
	Currency         string              `json:"currency"`
	PaymentMethod    string              `json:"payment_method"`
	LastPaymentError *StripePaymentError `json:"last_payment_error,omitempty"`
	Metadata         map[string]string   `json:"metadata"`
}

type StripePaymentError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Type    string `json:"type"`
}

type StripeRefund struct {
	PaymentIntent string            `json:"payment_intent"`
	Amount        int64             `json:"amount,omitempty"`
	Reason        string            `json:"reason,omitempty"`
	Metadata      map[string]string `json:"metadata,omitempty"`
}

type StripeRefundResponse struct {
	ID     string `json:"id"`
	Status string `json:"status"`
	Amount int64  `json:"amount"`
}

func (s *StripeProcessor) ProcessPayment(ctx context.Context, req ports.ProcessPaymentRequest) (*ports.ProcessPaymentResponse, error) {
	// Convert decimal amount to cents (Stripe uses smallest currency unit)
	amountCents := req.Amount.Mul(decimal.NewFromInt(100)).IntPart()

	paymentIntent := StripePaymentIntent{
		Amount:             amountCents,
		Currency:           string(req.Currency),
		PaymentMethodTypes: []string{"card"},
		ConfirmationMethod: "automatic",
		Confirm:            true,
	}

	// Extract payment method from payment details
	if paymentMethod, ok := req.PaymentDetails["payment_method"].(string); ok {
		paymentIntent.PaymentMethod = paymentMethod
	}

	// Add metadata
	if req.Metadata != nil {
		paymentIntent.Metadata = make(map[string]string)
		for k, v := range req.Metadata {
			if str, ok := v.(string); ok {
				paymentIntent.Metadata[k] = str
			}
		}
	}

	requestBody, err := json.Marshal(paymentIntent)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal payment intent: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST",
		s.config.BaseURL+"/v1/payment_intents", bytes.NewReader(requestBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	httpReq.Header.Set("Authorization", "Bearer "+s.config.APIKey)
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to execute HTTP request: %w", err)
	}
	defer resp.Body.Close()

	var stripeResp StripePaymentIntentResponse
	if err := json.NewDecoder(resp.Body).Decode(&stripeResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		errorMsg := "payment failed"
		if stripeResp.LastPaymentError != nil {
			errorMsg = stripeResp.LastPaymentError.Message
		}
		return nil, fmt.Errorf("stripe payment failed: %s", errorMsg)
	}

	status := s.mapStripeStatus(stripeResp.Status)

	return &ports.ProcessPaymentResponse{
		ProcessorRef: stripeResp.ID,
		Status:       status,
		Metadata: map[string]interface{}{
			"stripe_status":         stripeResp.Status,
			"stripe_payment_method": stripeResp.PaymentMethod,
		},
	}, nil
}

func (s *StripeProcessor) RefundPayment(ctx context.Context, req ports.RefundRequest) (*ports.RefundResponse, error) {
	amountCents := req.Amount.Mul(decimal.NewFromInt(100)).IntPart()

	refund := StripeRefund{
		PaymentIntent: req.ProcessorRef,
		Amount:        amountCents,
		Reason:        "requested_by_customer",
		Metadata:      map[string]string{"reason": req.Reason},
	}

	requestBody, err := json.Marshal(refund)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal refund request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST",
		s.config.BaseURL+"/v1/refunds", bytes.NewReader(requestBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	httpReq.Header.Set("Authorization", "Bearer "+s.config.APIKey)
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("failed to execute HTTP request: %w", err)
	}
	defer resp.Body.Close()

	var stripeResp StripeRefundResponse
	if err := json.NewDecoder(resp.Body).Decode(&stripeResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("stripe refund failed")
	}

	return &ports.RefundResponse{
		RefundRef: stripeResp.ID,
		Status:    domain.PaymentStatusRefunded,
	}, nil
}

func (s *StripeProcessor) GetPaymentStatus(ctx context.Context, processorRef string) (domain.PaymentStatus, error) {
	httpReq, err := http.NewRequestWithContext(ctx, "GET",
		s.config.BaseURL+"/v1/payment_intents/"+processorRef, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create HTTP request: %w", err)
	}

	httpReq.Header.Set("Authorization", "Bearer "+s.config.APIKey)

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return "", fmt.Errorf("failed to execute HTTP request: %w", err)
	}
	defer resp.Body.Close()

	var stripeResp StripePaymentIntentResponse
	if err := json.NewDecoder(resp.Body).Decode(&stripeResp); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	return s.mapStripeStatus(stripeResp.Status), nil
}

func (s *StripeProcessor) SupportsMethod(method domain.PaymentMethod) bool {
	switch method {
	case domain.PaymentMethodCard:
		return true
	default:
		return false
	}
}

func (s *StripeProcessor) SupportsCurrency(currency domain.Currency) bool {
	switch currency {
	case domain.CurrencyUSD, domain.CurrencyEUR, domain.CurrencyGBP:
		return true
	default:
		return false
	}
}

func (s *StripeProcessor) mapStripeStatus(stripeStatus string) domain.PaymentStatus {
	switch stripeStatus {
	case "succeeded":
		return domain.PaymentStatusCompleted
	case "processing":
		return domain.PaymentStatusProcessing
	case "requires_payment_method", "requires_confirmation", "requires_action":
		return domain.PaymentStatusPending
	case "canceled":
		return domain.PaymentStatusCancelled
	default:
		return domain.PaymentStatusFailed
	}
}

k
// internal/adapters/external/paypal/paypal_processor.go
package paypal

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"

    "payment-service/internal/config"
    "payment-service/internal/core/domain"
    "payment-service/internal/core/ports"
    "payment-service/pkg/logger"

    "github.com/shopspring/decimal"
)

type PayPalProcessor struct {
    config     config.ProcessorConfig
    httpClient *http.Client
    logger     logger.Logger
    accessToken string
    tokenExpiry time.Time
}

func NewPayPalProcessor(config config.ProcessorConfig, logger logger.Logger) ports.PaymentProcessor {
    return &PayPalProcessor{
        config: config,
        httpClient: &http.Client{
            Timeout: config.Timeout,
        },
        logger: logger,
    }
}

type PayPalOrder struct {
    Intent        string                 `json:"intent"`
    PurchaseUnits []PayPalPurchaseUnit   `json:"purchase_units"`
    PaymentSource PayPalPaymentSource    `json:"payment_source,omitempty"`
}

type PayPalPurchaseUnit struct {
    Amount PayPalAmount `json:"amount"`
}

type PayPalAmount struct {
    CurrencyCode string `json:"currency_code"`
    Value        string `json:"value"`
}

type PayPalPaymentSource struct {
    Card *PayPalCard `json:"card,omitempty"`
}

type PayPalCard struct {
    Number      string `json:"number"`
    ExpiryMonth string `json:"expiry_month"`
    ExpiryYear  string `json:"expiry_year"`
    SecurityCode string `json:"security_code"`
}

type PayPalOrderResponse struct {
    ID     string `json:"id"`
    Status string `json:"status"`
    Links  []PayPalLink `json:"links"`
}

type PayPalLink struct {
    Href   string `json:"href"`
    Rel    string `json:"rel"`
    Method string `json:"method"`
}

type PayPalAccessTokenResponse struct {
    AccessToken string `json:"access_token"`
    TokenType   string `json:"token_type"`
    ExpiresIn   int64  `json:"expires_in"`
}

func (p *PayPalProcessor) ProcessPayment(ctx context.Context, req ports.ProcessPaymentRequest) (*ports.ProcessPaymentResponse, error) {
    if err := p.ensureAccessToken(ctx); err != nil {
        return nil, fmt.Errorf("failed to get access token: %w", err)
    }

    // Create PayPal order
    order := PayPalOrder{
        Intent: "CAPTURE",
        PurchaseUnits: []PayPalPurchaseUnit{
            {
                Amount: PayPalAmount{
                    CurrencyCode: string(req.Currency),
                    Value:        req.Amount.String(),
                },
            },
        },
    }

    // Add payment method details if provided
    if cardDetails, ok := req.PaymentDetails["card"]; ok {
        if cardMap, ok := cardDetails.(map[string]interface{}); ok {
            order.PaymentSource = PayPalPaymentSource{
                Card: &PayPalCard{
                    Number:       cardMap["number"].(string),
                    ExpiryMonth:  cardMap["exp_month"].(string),
                    ExpiryYear:   cardMap["exp_year"].(string),
                    SecurityCode: cardMap["cvc"].(string),
                },
            }
        }
    }

    requestBody, err := json.Marshal(order)
    if err != nil {
        return nil, fmt.Errorf("failed to marshal order: %w", err)
    }

    httpReq, err := http.NewRequestWithContext(ctx, "POST",
        p.config.BaseURL+"/v2/checkout/orders", bytes.NewReader(requestBody))
    if err != nil {
        return nil, fmt.Errorf("failed to create HTTP request: %w", err)
    }

    httpReq.Header.Set("Authorization", "Bearer "+p.accessToken)
    httpReq.Header.Set("Content-Type", "application/json")
    httpReq.Header.Set("PayPal-Request-Id", fmt.Sprintf("req_%d", time.Now().UnixNano()))

    resp, err := p.httpClient.Do(httpReq)
    if err != nil {
        return nil, fmt.Errorf("failed to execute HTTP request: %w", err)
    }
    defer resp.Body.Close()

    var paypalResp PayPalOrderResponse
    if err := json.NewDecoder(resp.Body).Decode(&paypalResp); err != nil {
        return nil, fmt.Errorf("failed to decode response: %w", err)
    }

    if resp.StatusCode != http.StatusCreated {
        return nil, fmt.Errorf("paypal order creation failed: %s", paypalResp.Status)
    }

    // Capture the order
    captureResp, err := p.captureOrder(ctx, paypalResp.ID)
    if err != nil {
        return nil, fmt.Errorf("failed to capture order: %w", err)
    }

    status := p.mapPayPalStatus(captureResp.Status)

    return &ports.ProcessPaymentResponse{
        ProcessorRef: paypalResp.ID,
        Status:       status,
        Metadata: map[string]interface{}{
            "paypal_status": captureResp.Status,
            "paypal_id":     paypalResp.ID,
        },
    }, nil
}

func (p *PayPalProcessor) RefundPayment(ctx context.Context, req ports.RefundRequest) (*ports.RefundResponse, error) {
    if err := p.ensureAccessToken(ctx); err != nil {
        return nil, fmt.Errorf("failed to get access token: %w", err)
    }

    refund := map[string]interface{}{
        "amount": map[string]string{
            "currency_code": string(req.Currency),
            "value":         req.Amount.String(),
        },
        "note_to_payer": req.Reason,
    }

    requestBody, err := json.Marshal(refund)
    if err != nil {
        return nil, fmt.Errorf("failed to marshal refund: %w", err)
    }

    httpReq, err := http.NewRequestWithContext(ctx, "POST",
        fmt.Sprintf("%s/v2/payments/captures/%s/refund", p.config.BaseURL, req.ProcessorRef),
        bytes.NewReader(requestBody))
    if err != nil {
        return nil, fmt.Errorf("failed to create HTTP request: %w", err)
    }

    httpReq.Header.Set("Authorization", "Bearer "+p.accessToken)
    httpReq.Header.Set("Content-Type", "application/json")

    resp, err := p.httpClient.Do(httpReq)
    if err != nil {
        return nil, fmt.Errorf("failed to execute HTTP request: %w", err)
    }
    defer resp.Body.Close()

    var refundResp map[string]interface{}
    if err := json.NewDecoder(resp.Body).Decode(&refundResp); err != nil {
        return nil, fmt.Errorf("failed to decode response: %w", err)
    }

    if resp.StatusCode != http.StatusCreated {
        return nil, fmt.Errorf("paypal refund failed")
    }

    return &ports.RefundResponse{
        RefundRef: refundResp["id"].(string),
        Status:    domain.PaymentStatusRefunded,
    }, nil
}

func (p *PayPalProcessor) GetPaymentStatus(ctx context.Context, processorRef string) (domain.PaymentStatus, error) {
    if err := p.ensureAccessToken(ctx); err != nil {
        return "", fmt.Errorf("failed to get access token: %w

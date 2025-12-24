// internal/adapters/external/ml/fraud_ml_service.go
package ml

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"payment-service/internal/core/domain"
	"payment-service/pkg/logger"

	"github.com/shopspring/decimal"
)

type MLFraudService struct {
	httpClient   *http.Client
	mlServiceURL string
	apiKey       string
	logger       logger.Logger
}

func NewMLFraudService(mlServiceURL, apiKey string, logger logger.Logger) *MLFraudService {
	return &MLFraudService{
		httpClient: &http.Client{
			Timeout: 5 * time.Second,
		},
		mlServiceURL: mlServiceURL,
		apiKey:       apiKey,
		logger:       logger,
	}
}

type MLFraudRequest struct {
	Amount         decimal.Decimal        `json:"amount"`
	Currency       string                 `json:"currency"`
	Method         string                 `json:"method"`
	Country        string                 `json:"country"`
	Hour           int                    `json:"hour"`
	DayOfWeek      int                    `json:"day_of_week"`
	ClientHistory  *ClientHistoryFeatures `json:"client_history"`
	DeviceFeatures *DeviceFeatures        `json:"device_features"`
}

type ClientHistoryFeatures struct {
	TotalTransactions int64           `json:"total_transactions"`
	SuccessRate       decimal.Decimal `json:"success_rate"`
	AverageAmount     decimal.Decimal `json:"average_amount"`
	DaysSinceFirst    int             `json:"days_since_first"`
	RecentFailures    int             `json:"recent_failures"`
}

type DeviceFeatures struct {
	IsKnownDevice     bool `json:"is_known_device"`
	DeviceAge         int  `json:"device_age_days"`
	LocationChange    bool `json:"location_change"`
	VelocityViolation bool `json:"velocity_violation"`
}

type MLFraudResponse struct {
	RiskScore    decimal.Decimal     `json:"risk_score"`
	RiskLevel    string              `json:"risk_level"`
	Features     map[string]float64  `json:"features"`
	ModelVersion string              `json:"model_version"`
	Explanation  []FeatureImportance `json:"explanation"`
}

type FeatureImportance struct {
	Feature    string  `json:"feature"`
	Importance float64 `json:"importance"`
	Value      float64 `json:"value"`
}

func (m *MLFraudService) EvaluatePayment(ctx context.Context, payment *domain.Payment, features map[string]interface{}) (*MLFraudResponse, error) {
	if m.mlServiceURL == "" {
		// Return default low-risk response if ML service is not configured
		return &MLFraudResponse{
			RiskScore:    decimal.NewFromFloat(0.1),
			RiskLevel:    "low",
			ModelVersion: "fallback",
		}, nil
	}

	request := MLFraudRequest{
		Amount:    payment.Amount,
		Currency:  string(payment.Currency),
		Method:    string(payment.Method),
		Country:   m.extractFeature(features, "country", "US"),
		Hour:      time.Now().Hour(),
		DayOfWeek: int(time.Now().Weekday()),
		ClientHistory: &ClientHistoryFeatures{
			TotalTransactions: m.extractFeatureInt64(features, "total_transactions", 0),
			SuccessRate:       m.extractFeatureDecimal(features, "success_rate", decimal.NewFromFloat(0.9)),
			AverageAmount:     m.extractFeatureDecimal(features, "average_amount", decimal.NewFromInt(100)),
			DaysSinceFirst:    m.extractFeatureInt(features, "days_since_first", 0),
			RecentFailures:    m.extractFeatureInt(features, "recent_failures", 0),
		},
		DeviceFeatures: &DeviceFeatures{
			IsKnownDevice:     m.extractFeatureBool(features, "is_known_device", false),
			DeviceAge:         m.extractFeatureInt(features, "device_age_days", 0),
			LocationChange:    m.extractFeatureBool(features, "location_change", false),
			VelocityViolation: m.extractFeatureBool(features, "velocity_violation", false),
		},
	}

	reqBody, err := json.Marshal(request)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal ML request: %w", err)
	}

	httpReq, err := http.NewRequestWithContext(ctx, "POST",
		m.mlServiceURL+"/api/v1/fraud/predict", bytes.NewReader(reqBody))
	if err != nil {
		return nil, fmt.Errorf("failed to create HTTP request: %w", err)
	}

	httpReq.Header.Set("Authorization", "Bearer "+m.apiKey)
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := m.httpClient.Do(httpReq)
	if err != nil {
		m.logger.Warn("ML service unavailable, using fallback", map[string]interface{}{
			"error":      err.Error(),
			"payment_id": payment.ID.String(),
		})
		return &MLFraudResponse{
			RiskScore:    decimal.NewFromFloat(0.2),
			RiskLevel:    "low",
			ModelVersion: "fallback_unavailable",
		}, nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("ML service returned status: %d", resp.StatusCode)
	}

	var mlResp MLFraudResponse
	if err := json.NewDecoder(resp.Body).Decode(&mlResp); err != nil {
		return nil, fmt.Errorf("failed to decode ML response: %w", err)
	}

	m.logger.Info("ML fraud evaluation completed", map[string]interface{}{
		"payment_id":    payment.ID.String(),
		"risk_score":    mlResp.RiskScore.String(),
		"risk_level":    mlResp.RiskLevel,
		"model_version": mlResp.ModelVersion,
	})

	return &mlResp, nil
}

// Helper methods for feature extraction
func (m *MLFraudService) extractFeature(features map[string]interface{}, key, defaultValue string) string {
	if val, exists := features[key]; exists {
		if str, ok := val.(string); ok {
			return str
		}
	}
	return defaultValue
}

func (m *MLFraudService) extractFeatureInt64(features map[string]interface{}, key string, defaultValue int64) int64 {
	if val, exists := features[key]; exists {
		if i, ok := val.(int64); ok {
			return i
		}
		if f, ok := val.(float64); ok {
			return int64(f)
		}
	}
	return defaultValue
}

func (m *MLFraudService) extractFeatureInt(features map[string]interface{}, key string, defaultValue int) int {
	return int(m.extractFeatureInt64(features, key, int64(defaultValue)))
}

func (m *MLFraudService) extractFeatureDecimal(features map[string]interface{}, key string, defaultValue decimal.Decimal) decimal.Decimal {
	if val, exists := features[key]; exists {
		if f, ok := val.(float64); ok {
			return decimal.NewFromFloat(f)
		}
		if str, ok := val.(string); ok {
			if dec, err := decimal.NewFromString(str); err == nil {
				return dec
			}
		}
	}
	return defaultValue
}

func (m *MLFraudService) extractFeatureBool(features map[string]interface{}, key string, defaultValue bool) bool {
	if val, exists := features[key]; exists {
		if b, ok := val.(bool); ok {
			return b
		}
	}
	return defaultValue
}

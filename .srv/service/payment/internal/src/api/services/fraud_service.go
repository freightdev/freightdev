// internal/core/services/fraud_service.go
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

type FraudServiceImpl struct {
    paymentRepo ports.PaymentRepository
    cacheService ports.CacheService
    logger      logger.Logger

    // Fraud detection rules
    maxAmountPerHour    decimal.Decimal
    maxTransactionsPerHour int
    velocityWindow      time.Duration
    suspiciousCountries []string
}

func NewFraudService(
    paymentRepo ports.PaymentRepository,
    cacheService ports.CacheService,
    logger logger.Logger,
) ports.FraudService {
    return &FraudServiceImpl{
        paymentRepo:            paymentRepo,
        cacheService:           cacheService,
        logger:                 logger,
        maxAmountPerHour:       decimal.NewFromInt(10000),
        maxTransactionsPerHour: 50,
        velocityWindow:         time.Hour,
        suspiciousCountries:    []string{"XX", "YY"}, // Configure based on risk assessment
    }
}

func (f *FraudServiceImpl) CheckPayment(ctx context.Context, req ports.FraudCheckRequest) (*domain.FraudCheck, error) {
    fraudCheck := domain.NewFraudCheck(req.Payment.ID, req.IPAddress)
    fraudCheck.DeviceID = req.DeviceID

    // Run fraud checks
    f.checkVelocity(ctx, req, fraudCheck)
    f.checkAmount(ctx, req, fraudCheck)
    f.checkLocation(ctx, req, fraudCheck)
    f.checkDevice(ctx, req, fraudCheck)

    // Calculate overall risk score
    riskScore := f.calculateRiskScore(fraudCheck)
    fraudCheck.RiskScore = riskScore

    // Determine risk level
    if riskScore.GreaterThanOrEqual(decimal.NewFromFloat(0.8)) {
        fraudCheck.RiskLevel = domain.FraudRiskBlocked
    } else if riskScore.GreaterThanOrEqual(decimal.NewFromFloat(0.6)) {
        fraudCheck.RiskLevel = domain.FraudRiskHigh
    } else if riskScore.GreaterThanOrEqual(decimal.NewFromFloat(0.3)) {
        fraudCheck.RiskLevel = domain.FraudRiskMedium
    } else {
        fraudCheck.RiskLevel = domain.FraudRiskLow
    }

    f.logger.Info("Fraud check completed", map[string]interface{}{
        "payment_id":  req.Payment.ID.String(),
        "risk_level":  string(fraudCheck.RiskLevel),
        "risk_score":  fraudCheck.RiskScore.String(),
        "reasons":     fraudCheck.Reasons,
    })

    return fraudCheck, nil
}

func (f *FraudServiceImpl) checkVelocity(ctx context.Context, req ports.FraudCheckRequest, fraudCheck *domain.FraudCheck) {
    // Check transaction velocity by client
    velocityKey := fmt.Sprintf("velocity:client:%s", req.Payment.ClientID)

    // Get current count
    current, _ := f.cacheService.Increment(ctx, velocityKey, 1)
    if current == 1 {
        // First transaction in window, set expiration
        f.cacheService.Set(ctx, velocityKey+"_exp", []byte("1"), f.velocityWindow)
    }

    if current > int64(f.maxTransactionsPerHour) {
        fraudCheck.AddReason(domain.FraudReasonVelocity, map[string]interface{}{
            "transactions_per_hour": current,
            "limit":                 f.maxTransactionsPerHour,
        })
    }

    // Check amount velocity
    amountKey := fmt.Sprintf("amount:client:%s", req.Payment.ClientID)
    amountData, _ := f.cacheService.Get(ctx, amountKey)

    var totalAmount decimal.Decimal
    if amountData != nil {
        totalAmount, _ = decimal.NewFromString(string(amountData))
    }

    totalAmount = totalAmount.Add(req.Payment.Amount)
    f.cacheService.Set(ctx, amountKey, []byte(totalAmount.String()), f.velocityWindow)

    if totalAmount.GreaterThan(f.maxAmountPerHour) {
        fraudCheck.AddReason(domain.FraudReasonVelocity, map[string]interface{}{
            "amount_per_hour": totalAmount.String(),
            "limit":           f.maxAmountPerHour.String(),
        })
    }
}

func (f *FraudServiceImpl) checkAmount(ctx context.Context, req ports.FraudCheckRequest, fraudCheck *domain.FraudCheck) {
    // Check for unusual amounts (round numbers, very high amounts)
    amount := req.Payment.Amount

    // Check if amount is suspiciously round
    if amount.Mod(decimal.NewFromInt(1000)).IsZero() && amount.GreaterThan(decimal.NewFromInt(5000)) {
        fraudCheck.AddReason(domain.FraudReasonAmount, map[string]interface{}{
            "reason": "suspiciously_round_amount",
            "amount": amount.String(),
        })
    }

    // Check for unusually high amounts for this client
    // This would typically involve ML models or historical analysis
    if amount.GreaterThan(decimal.NewFromInt(50000)) {
        fraudCheck.AddReason(domain.FraudReasonAmount, map[string]interface{}{
            "reason": "high_amount",
            "amount": amount.String(),
        })
    }
}

func (f *FraudServiceImpl) checkLocation(ctx context.Context, req ports.FraudCheckRequest, fraudCheck *domain.FraudCheck) {
    // This would typically involve GeoIP lookup
    // For demo purposes, we'll simulate some checks

    // Check if IP is from suspicious country
    // In real implementation, use a GeoIP service
    ipCountry := f.getCountryFromIP(fraudCheck.IPAddress)

    for _, suspicious := range f.suspiciousCountries {
        if ipCountry == suspicious {
            fraudCheck.AddReason(domain.FraudReasonLocation, map[string]interface{}{
                "country":    ipCountry,
                "ip_address": fraudCheck.IPAddress,
            })
            break
        }
    }
}

func (f *FraudServiceImpl) checkDevice(ctx context.Context, req ports.FraudCheckRequest, fraudCheck *domain.FraudCheck) {
    if fraudCheck.DeviceID != "" {
        // Check if device is known/trusted
        deviceKey := fmt.Sprintf("device:%s", fraudCheck.DeviceID)

        exists, _ := f.cacheService.Exists(ctx, deviceKey)
        if !exists {
            fraudCheck.AddReason(domain.FraudReasonDevice, map[string]interface{}{
                "reason":    "unknown_device",
                "device_id": fraudCheck.DeviceID,
            })
        }
    }
}

func (f *FraudServiceImpl) calculateRiskScore(fraudCheck *domain.FraudCheck) decimal.Decimal {
    score := decimal.Zero

    // Weight different risk factors
    weights := map[domain.FraudReason]decimal.Decimal{
        domain.FraudReasonVelocity:  decimal.NewFromFloat(0.3),
        domain.FraudReasonAmount:    decimal.NewFromFloat(0.2),
        domain.FraudReasonLocation:  decimal.NewFromFloat(0.25),
        domain.FraudReasonDevice:    decimal.NewFromFloat(0.15),
        domain.FraudReasonBehavior:  decimal.NewFromFloat(0.2),
        domain.FraudReasonBlacklist: decimal.NewFromFloat(0.9),
        domain.FraudReasonMLModel:   decimal.NewFromFloat(0.4),
    }

    for _, reason := range fraudCheck.Reasons {
        if weight, exists := weights[reason]; exists {
            score = score.Add(weight)
        }
    }

    // Cap at 1.0
    if score.GreaterThan(decimal.NewFromInt(1)) {
        score = decimal.NewFromInt(1)
    }

    return score
}

func (f *FraudServiceImpl) getCountryFromIP(ipAddress string) string {
    // This would integrate with a GeoIP service like MaxMind
    // For demo purposes, return a placeholder
    return "US"
}

func (f *FraudServiceImpl) GetFraudCheck(ctx context.Context, paymentID uuid.UUID) (*domain.FraudCheck, error) {
    // Implementation would retrieve from database
    return nil, fmt.Errorf("not implemented")
}

func (f *FraudServiceImpl) ReviewFraudCheck(ctx context.Context, fraudCheckID uuid.UUID, reviewerID, notes string) error {
    // Implementation would update fraud check with review
    return fmt.Errorf("not implemented")
}

func (f *FraudServiceImpl) GetFraudStats(ctx context.Context, clientID string, period time.Duration) (*ports.FraudStats, error) {
    // Implementation

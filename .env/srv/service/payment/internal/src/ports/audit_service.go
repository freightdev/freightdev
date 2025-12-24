// internal/core/ports/audit_service.go
package ports

import (
	"context"
	"payment-service/internal/core/domain"
	"time"
)

type AuditService interface {
	Log(ctx context.Context, log *domain.AuditLog) error
	GetAuditTrail(ctx context.Context, entityType, entityID string) ([]*domain.AuditLog, error)
	SearchAuditLogs(ctx context.Context, req AuditSearchRequest) ([]*domain.AuditLog, error)
	GetAuditStats(ctx context.Context, clientID string, period time.Duration) (*AuditStats, error)
}

type AuditSearchRequest struct {
	ClientID   string    `json:"client_id"`
	UserID     string    `json:"user_id,omitempty"`
	EntityType string    `json:"entity_type,omitempty"`
	Action     string    `json:"action,omitempty"`
	IPAddress  string    `json:"ip_address,omitempty"`
	StartTime  time.Time `json:"start_time,omitempty"`
	EndTime    time.Time `json:"end_time,omitempty"`
	Limit      int       `json:"limit"`
	Offset     int       `json:"offset"`
}

type AuditStats struct {
	TotalActions       int64                     `json:"total_actions"`
	ActionsByType      map[string]int64          `json:"actions_by_type"`
	TopUsers           []UserActivitySummary     `json:"top_users"`
	TopIPs             []IPActivitySummary       `json:"top_ips"`
	SuspiciousActivity []SuspiciousActivityAlert `json:"suspicious_activity"`
}

type UserActivitySummary struct {
	UserID      string `json:"user_id"`
	ActionCount int64  `json:"action_count"`
}

type IPActivitySummary struct {
	IPAddress   string `json:"ip_address"`
	ActionCount int64  `json:"action_count"`
	UniqueUsers int64  `json:"unique_users"`
}

type SuspiciousActivityAlert struct {
	Type        string                 `json:"type"`
	Description string                 `json:"description"`
	Severity    string                 `json:"severity"`
	Timestamp   time.Time              `json:"timestamp"`
	Details     map[string]interface{} `json:"details"`
}

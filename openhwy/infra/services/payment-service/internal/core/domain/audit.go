// internal/core/domain/audit.go
package domain

import (
	"time"

	"github.com/google/uuid"
)

type AuditAction string

const (
	AuditActionCreate  AuditAction = "create"
	AuditActionUpdate  AuditAction = "update"
	AuditActionProcess AuditAction = "process"
	AuditActionRefund  AuditAction = "refund"
	AuditActionCancel  AuditAction = "cancel"
	AuditActionView    AuditAction = "view"
	AuditActionExport  AuditAction = "export"
)

type AuditLog struct {
	ID            uuid.UUID              `json:"id"`
	EntityType    string                 `json:"entity_type"`
	EntityID      string                 `json:"entity_id"`
	Action        AuditAction            `json:"action"`
	UserID        string                 `json:"user_id,omitempty"`
	ClientID      string                 `json:"client_id"`
	IPAddress     string                 `json:"ip_address"`
	UserAgent     string                 `json:"user_agent,omitempty"`
	Changes       map[string]interface{} `json:"changes,omitempty"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
	Timestamp     time.Time              `json:"timestamp"`
	CorrelationID string                 `json:"correlation_id"`
}

func NewAuditLog(entityType, entityID, action, userID, clientID, ipAddress string) *AuditLog {
	return &AuditLog{
		ID:         uuid.New(),
		EntityType: entityType,
		EntityID:   entityID,
		Action:     AuditAction(action),
		UserID:     userID,
		ClientID:   clientID,
		IPAddress:  ipAddress,
		Changes:    make(map[string]interface{}),
		Metadata:   make(map[string]interface{}),
		Timestamp:  time.Now().UTC(),
	}
}

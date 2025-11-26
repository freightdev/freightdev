// internal/domain/entities/session.go
package entities

import (
	"time"

	"github.com/google/uuid"
)

// Session represents a user session
type Session struct {
	ID        uuid.UUID `json:"id" db:"id"`
	UserID    uuid.UUID `json:"user_id" db:"user_id"`
	Token     string    `json:"token" db:"token"`
	ExpiresAt time.Time `json:"expires_at" db:"expires_at"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	IPAddress string    `json:"ip_address" db:"ip_address"`
	UserAgent string    `json:"user_agent" db:"user_agent"`
	IsRevoked bool      `json:"is_revoked" db:"is_revoked"`
}

// IsExpired checks if the session has expired
func (s *Session) IsExpired() bool {
	return time.Now().After(s.ExpiresAt)
}

// IsValid checks if the session is valid (not expired and not revoked)
func (s *Session) IsValid() bool {
	return !s.IsExpired() && !s.IsRevoked
}

// Revoke marks the session as revoked
func (s *Session) Revoke() {
	s.IsRevoked = true
}

// internal/middleware/cors.go
package middleware

import (
	"fmt"
	"net/http"
	"strings"

	"auth-service/internal/config"
)

// CORSMiddleware provides CORS support
type CORSMiddleware struct {
	config *config.CORSConfig
}

// NewCORSMiddleware creates a new CORS middleware
func NewCORSMiddleware(config *config.CORSConfig) *CORSMiddleware {
	return &CORSMiddleware{
		config: config,
	}
}

// EnableCORS enables CORS headers
func (m *CORSMiddleware) EnableCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")

		// Check if origin is allowed
		if m.isOriginAllowed(origin) {
			w.Header().Set("Access-Control-Allow-Origin", origin)
		}

		w.Header().Set("Access-Control-Allow-Methods", strings.Join(m.config.AllowedMethods, ", "))
		w.Header().Set("Access-Control-Allow-Headers", strings.Join(m.config.AllowedHeaders, ", "))
		w.Header().Set("Access-Control-Max-Age", fmt.Sprintf("%d", m.config.MaxAge))
		w.Header().Set("Access-Control-Allow-Credentials", "true")

		// Handle preflight requests
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func (m *CORSMiddleware) isOriginAllowed(origin string) bool {
	for _, allowed := range m.config.AllowedOrigins {
		if allowed == "*" || allowed == origin {
			return true
		}
	}
	return false
}

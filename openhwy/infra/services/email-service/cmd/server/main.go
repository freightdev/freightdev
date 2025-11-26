package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/freightdev/email-service/internal/config"
	"github.com/freightdev/email-service/internal/handlers"
	"github.com/freightdev/email-service/internal/services"
)

func main() {
	fmt.Println("╔════════════════════════════════════════════════════════════╗")
	fmt.Println("║              📧 Email Service Starting 📧                  ║")
	fmt.Println("╚════════════════════════════════════════════════════════════╝")
	fmt.Println()

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	fmt.Printf("User Email: %s\n", cfg.UserEmail)
	fmt.Printf("SMTP: %s:%d\n", cfg.SMTPHost, cfg.SMTPPort)
	if cfg.SMTPUsername == "" {
		fmt.Println("⚠️  SMTP not configured - emails will be logged only")
		fmt.Println("   Run: cp .env.example .env and configure")
	} else {
		fmt.Println("✅ SMTP configured")
	}
	fmt.Println()

	// Initialize services
	emailService := services.NewEmailService(cfg)

	// Initialize handlers
	emailHandler := handlers.NewEmailHandler(emailService)

	// Setup routes
	http.HandleFunc("/health", emailHandler.Health)
	http.HandleFunc("/email/approval", emailHandler.SendApproval)
	http.HandleFunc("/email/digest", emailHandler.SendDigest)
	http.HandleFunc("/email/notification", emailHandler.SendNotification)
	http.HandleFunc("/email/status", emailHandler.SendStatus)
	http.HandleFunc("/email/alert", emailHandler.SendAlert)

	// Start server
	addr := fmt.Sprintf(":%s", cfg.Port)
	fmt.Printf("🚀 Email Service listening on http://localhost%s\n", addr)
	fmt.Println()
	fmt.Println("Endpoints:")
	fmt.Println("  GET  /health                - Health check")
	fmt.Println("  POST /email/approval        - Send approval request")
	fmt.Println("  POST /email/digest          - Send daily digest")
	fmt.Println("  POST /email/notification    - Send notification")
	fmt.Println("  POST /email/status          - Send status report")
	fmt.Println("  POST /email/alert           - Send alert")
	fmt.Println()

	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

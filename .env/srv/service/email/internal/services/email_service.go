package services

import (
	"fmt"
	"time"

	"github.com/freightdev/email-service/internal/config"
	"gopkg.in/gomail.v2"
)

type EmailService struct {
	config *config.Config
	dialer *gomail.Dialer
}

func NewEmailService(cfg *config.Config) *EmailService {
	dialer := gomail.NewDialer(
		cfg.SMTPHost,
		cfg.SMTPPort,
		cfg.SMTPUsername,
		cfg.SMTPPassword,
	)

	return &EmailService{
		config: cfg,
		dialer: dialer,
	}
}

// SendApprovalRequest sends an approval request to the user
func (s *EmailService) SendApprovalRequest(approvalID, action, riskLevel, details, recommendation string) error {
	subject := fmt.Sprintf("🚛 CoDriver Approval Needed: %s", action)

	body := fmt.Sprintf(`Hi Jesse,

CoDriver needs your approval for the following action:

┌────────────────────────────────────────────────┐
│ ACTION: %s
│ RISK LEVEL: %s
│ RECOMMENDATION: %s
└────────────────────────────────────────────────┘

DETAILS:
%s

TO APPROVE:
Reply with: APPROVE %s

TO DENY:
Reply with: DENY %s

Or visit: http://localhost:9009/approval/decide?id=%s

This approval request will expire in 24 hours.

---
Your autonomous AI co-pilot,
CoDriver 🚛🤖
`,
		action, riskLevel, recommendation, details,
		approvalID, approvalID, approvalID)

	return s.sendEmail(subject, body)
}

// SendDailyDigest sends the daily trucking intelligence digest
func (s *EmailService) SendDailyDigest(date, summary string, freightRates *FreightRates, newsCount, regCount int) error {
	subject := fmt.Sprintf("🚛 Daily Trucking Intel - %s", date)

	body := fmt.Sprintf(`Hi Jesse,

Here's your daily trucking intelligence summary for %s:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`, date)

	// Add freight rates if available
	if freightRates != nil {
		body += fmt.Sprintf(`
📊 FREIGHT RATES

Van:      $%.2f/mile  %s
Reefer:   $%.2f/mile  %s
Flatbed:  $%.2f/mile  %s

Overall Trend: %s

`,
			freightRates.VanRate, trendArrow(freightRates.VanTrend),
			freightRates.ReeferRate, trendArrow(freightRates.ReeferTrend),
			freightRates.FlatbedRate, trendArrow(freightRates.FlatbedTrend),
			freightRates.OverallTrend)
	}

	body += fmt.Sprintf(`📰 NEWS & UPDATES

%d new articles collected
%d regulatory updates

SUMMARY:
%s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

View full report: ~/.ai/data/trucking/%s/all.md
Query database: http://192.168.12.66:9000

---
CoDriver 🚛🤖
Autonomous Trucking Intelligence Agent
`,
		newsCount, regCount, summary, date)

	return s.sendEmail(subject, body)
}

// SendNotification sends a general notification
func (s *EmailService) SendNotification(title, message string, priority Priority) error {
	emoji := "📢"
	switch priority {
	case PriorityLow:
		emoji = "ℹ️"
	case PriorityHigh:
		emoji = "⚠️"
	case PriorityCritical:
		emoji = "🚨"
	}

	subject := fmt.Sprintf("%s CoDriver: %s", emoji, title)
	body := fmt.Sprintf(`Hi Jesse,

%s

%s

---
CoDriver 🚛🤖
`, title, message)

	return s.sendEmail(subject, body)
}

// SendStatusReport sends a system status report
func (s *EmailService) SendStatusReport(agentsOnline, agentsOffline []string, recentDecisions []string, pendingApprovals int) error {
	subject := "🚛 CoDriver Status Report"

	offlineSection := ""
	if len(agentsOffline) > 0 {
		offlineSection = fmt.Sprintf("\n🔴 AGENTS OFFLINE (%d):\n", len(agentsOffline))
		for _, agent := range agentsOffline {
			offlineSection += fmt.Sprintf("- %s\n", agent)
		}
	}

	decisionsSection := ""
	for _, decision := range recentDecisions {
		decisionsSection += fmt.Sprintf("- %s\n", decision)
	}

	body := fmt.Sprintf(`Hi Jesse,

CoDriver Status Report
Time: %s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 AGENTS ONLINE (%d):
%s
%s
📋 RECENT DECISIONS:
%s

⏳ PENDING APPROVALS: %d

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

View full status: http://localhost:9009/pending

---
CoDriver 🚛🤖
`,
		time.Now().UTC().Format("2006-01-02 15:04:05 UTC"),
		len(agentsOnline),
		formatList(agentsOnline),
		offlineSection,
		decisionsSection,
		pendingApprovals)

	return s.sendEmail(subject, body)
}

// SendAlert sends an error/alert email
func (s *EmailService) SendAlert(errorMsg, details string) error {
	subject := "🚨 CoDriver Alert"

	body := fmt.Sprintf(`Hi Jesse,

CoDriver encountered an issue that needs your attention:

ERROR: %s

DETAILS:
%s

RECOMMENDATION:
Check CoDriver logs: journalctl --user -u codriver-autonomous.service -n 50

---
CoDriver 🚛🤖
`, errorMsg, details)

	return s.sendEmail(subject, body)
}

// Core email sending function
func (s *EmailService) sendEmail(subject, body string) error {
	// If SMTP not configured, just log
	if s.config.SMTPUsername == "" || s.config.SMTPPassword == "" {
		fmt.Printf("⚠️  Email not configured - would send:\n")
		fmt.Printf("To: %s\n", s.config.UserEmail)
		fmt.Printf("Subject: %s\n", subject)
		fmt.Printf("Body:\n%s\n", body)
		return nil
	}

	m := gomail.NewMessage()
	m.SetHeader("From", fmt.Sprintf("%s <%s>", s.config.FromName, s.config.FromEmail))
	m.SetHeader("To", s.config.UserEmail)
	m.SetHeader("Subject", subject)
	m.SetBody("text/plain", body)

	if err := s.dialer.DialAndSend(m); err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}

	fmt.Printf("📧 Email sent to %s: %s\n", s.config.UserEmail, subject)
	return nil
}

// Helper types
type FreightRates struct {
	VanRate       float64
	VanTrend      string
	ReeferRate    float64
	ReeferTrend   string
	FlatbedRate   float64
	FlatbedTrend  string
	OverallTrend  string
}

type Priority int

const (
	PriorityLow Priority = iota
	PriorityNormal
	PriorityHigh
	PriorityCritical
)

func trendArrow(trend string) string {
	switch trend {
	case "rising":
		return "↑"
	case "falling":
		return "↓"
	default:
		return "→"
	}
}

func formatList(items []string) string {
	result := ""
	for _, item := range items {
		result += fmt.Sprintf("- %s\n", item)
	}
	return result
}

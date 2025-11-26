// internal/adapters/external/notification/email_service.go
package notification

import (
	"bytes"
	"context"
	"fmt"
	"html/template"
	"net/smtp"

	"payment-service/internal/core/domain"
	"payment-service/pkg/logger"
)

type EmailService struct {
	smtpHost     string
	smtpPort     string
	smtpUser     string
	smtpPassword string
	fromAddress  string
	templates    map[string]*template.Template
	logger       logger.Logger
}

func NewEmailService(host, port, user, password, fromAddr string, logger logger.Logger) *EmailService {
	service := &EmailService{
		smtpHost:     host,
		smtpPort:     port,
		smtpUser:     user,
		smtpPassword: password,
		fromAddress:  fromAddr,
		templates:    make(map[string]*template.Template),
		logger:       logger,
	}

	service.loadTemplates()
	return service
}

func (e *EmailService) NotifyPaymentCreated(ctx context.Context, payment *domain.Payment) error {
	return e.sendPaymentNotification("payment_created", payment)
}

func (e *EmailService) NotifyPaymentProcessed(ctx context.Context, payment *domain.Payment) error {
	return e.sendPaymentNotification("payment_processed", payment)
}

func (e *EmailService) NotifyPaymentFailed(ctx context.Context, payment *domain.Payment) error {
	return e.sendPaymentNotification("payment_failed", payment)
}

func (e *EmailService) NotifyPaymentRefunded(ctx context.Context, payment *domain.Payment) error {
	return e.sendPaymentNotification("payment_refunded", payment)
}

func (e *EmailService) sendPaymentNotification(templateName string, payment *domain.Payment) error {
	// In a real implementation, you'd get recipient email from client settings
	recipientEmail := fmt.Sprintf("notifications@client-%s.com", payment.ClientID)

	tmpl, exists := e.templates[templateName]
	if !exists {
		return fmt.Errorf("template not found: %s", templateName)
	}

	var body bytes.Buffer
	if err := tmpl.Execute(&body, payment); err != nil {
		return fmt.Errorf("failed to execute template: %w", err)
	}

	subject := e.getSubjectForTemplate(templateName, payment)

	return e.sendEmail(recipientEmail, subject, body.String())
}

func (e *EmailService) sendEmail(to, subject, body string) error {
	auth := smtp.PlainAuth("", e.smtpUser, e.smtpPassword, e.smtpHost)

	msg := []byte(fmt.Sprintf("To: %s\r\n"+
		"From: %s\r\n"+
		"Subject: %s\r\n"+
		"Content-Type: text/html; charset=\"UTF-8\"\r\n"+
		"\r\n"+
		"%s\r\n", to, e.fromAddress, subject, body))

	addr := fmt.Sprintf("%s:%s", e.smtpHost, e.smtpPort)

	err := smtp.SendMail(addr, auth, e.fromAddress, []string{to}, msg)
	if err != nil {
		e.logger.Error("Failed to send email", map[string]interface{}{
			"to":      to,
			"subject": subject,
			"error":   err.Error(),
		})
		return fmt.Errorf("failed to send email: %w", err)
	}

	e.logger.Info("Email sent successfully", map[string]interface{}{
		"to":      to,
		"subject": subject,
	})

	return nil
}

func (e *EmailService) loadTemplates() {
	templates := map[string]string{
		"payment_created": `
            <h2>Payment Created</h2>
            <p>A new payment has been created:</p>
            <ul>
                <li>Payment ID: {{.ID}}</li>
                <li>Order ID: {{.OrderID}}</li>
                <li>Amount: {{.Amount}} {{.Currency}}</li>
                <li>Status: {{.Status}}</li>
                <li>Created: {{.CreatedAt.Format "2006-01-02 15:04:05"}}</li>
            </ul>
        `,
		"payment_processed": `
            <h2>Payment Processed</h2>
            <p>Payment has been successfully processed:</p>
            <ul>
                <li>Payment ID: {{.ID}}</li>
                <li>Order ID: {{.OrderID}}</li>
                <li>Amount: {{.Amount}} {{.Currency}}</li>
                <li>Status: {{.Status}}</li>
                <li>Processed: {{.ProcessedAt.Format "2006-01-02 15:04:05"}}</li>
            </ul>
        `,
		"payment_failed": `
            <h2>Payment Failed</h2>
            <p>Payment processing failed:</p>
            <ul>
                <li>Payment ID: {{.ID}}</li>
                <li>Order ID: {{.OrderID}}</li>
                <li>Amount: {{.Amount}} {{.Currency}}</li>
                <li>Reason: {{.FailureReason}}</li>
                <li>Failed: {{.UpdatedAt.Format "2006-01-02 15:04:05"}}</li>
            </ul>
        `,
		"payment_refunded": `
            <h2>Payment Refunded</h2>
            <p>Payment has been refunded:</p>
            <ul>
                <li>Payment ID: {{.ID}}</li>
                <li>Order ID: {{.OrderID}}</li>
                <li>Amount: {{.Amount}} {{.Currency}}</li>
                <li>Refunded: {{.UpdatedAt.Format "2006-01-02 15:04:05"}}</li>
            </ul>
        `,
	}

	for name, tmplStr := range templates {
		tmpl, err := template.New(name).Parse(tmplStr)
		if err != nil {
			e.logger.Error("Failed to parse template", map[string]interface{}{
				"template": name,
				"error":    err.Error(),
			})
			continue
		}
		e.templates[name] = tmpl
	}
}

func (e *EmailService) getSubjectForTemplate(templateName string, payment *domain.Payment) string {
	subjects := map[string]string{
		"payment_created":   "Payment Created - Order #%s",
		"payment_processed": "Payment Successful - Order #%s",
		"payment_failed":    "Payment Failed - Order #%s",
		"payment_refunded":  "Payment Refunded - Order #%s",
	}

	if subject, exists := subjects[templateName]; exists {
		return fmt.Sprintf(subject, payment.OrderID)
	}

	return "Payment Notification"
}

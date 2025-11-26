package config

import (
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	Port               string
	UserEmail          string
	SMTPHost           string
	SMTPPort           int
	SMTPUsername       string
	SMTPPassword       string
	FromEmail          string
	FromName           string
	TemplateDir        string
	EnableDailyDigest  bool
	DailyDigestTime    string
	EnableApprovals    bool
	EnableNotifications bool
}

func Load() (*Config, error) {
	// Load .env file if it exists
	godotenv.Load()

	smtpPort, _ := strconv.Atoi(getEnv("SMTP_PORT", "587"))

	return &Config{
		Port:                getEnv("PORT", "9011"),
		UserEmail:           getEnv("USER_EMAIL", "jesse.freightdev@gmail.com"),
		SMTPHost:            getEnv("SMTP_HOST", "smtp.gmail.com"),
		SMTPPort:            smtpPort,
		SMTPUsername:        getEnv("SMTP_USERNAME", ""),
		SMTPPassword:        getEnv("SMTP_PASSWORD", ""),
		FromEmail:           getEnv("FROM_EMAIL", "codriver@localhost"),
		FromName:            getEnv("FROM_NAME", "CoDriver AI Agent"),
		TemplateDir:         getEnv("TEMPLATE_DIR", "./templates"),
		EnableDailyDigest:   getEnv("ENABLE_DAILY_DIGEST", "true") == "true",
		DailyDigestTime:     getEnv("DAILY_DIGEST_TIME", "08:00"),
		EnableApprovals:     getEnv("ENABLE_APPROVAL_EMAILS", "true") == "true",
		EnableNotifications: getEnv("ENABLE_NOTIFICATIONS", "true") == "true",
	}, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

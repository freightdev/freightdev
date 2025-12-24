// pkg/logger/logger.go
package logger

import (
	"encoding/json"
	"log"
	"os"
	"time"
)

type LogLevel int

const (
	DEBUG LogLevel = iota
	INFO
	WARN
	ERROR
)

func (l LogLevel) String() string {
	switch l {
	case DEBUG:
		return "DEBUG"
	case INFO:
		return "INFO"
	case WARN:
		return "WARN"
	case ERROR:
		return "ERROR"
	default:
		return "UNKNOWN"
	}
}

type Logger interface {
	Debug(msg string, fields map[string]interface{})
	Info(msg string, fields map[string]interface{})
	Warn(msg string, fields map[string]interface{})
	Error(msg string, fields map[string]interface{})
	With(fields map[string]interface{}) Logger
}

type StructuredLogger struct {
	level  LogLevel
	fields map[string]interface{}
	logger *log.Logger
}

func NewLogger(level LogLevel) Logger {
	return &StructuredLogger{
		level:  level,
		fields: make(map[string]interface{}),
		logger: log.New(os.Stdout, "", 0),
	}
}

func (l *StructuredLogger) Debug(msg string, fields map[string]interface{}) {
	if l.level <= DEBUG {
		l.log(DEBUG, msg, fields)
	}
}

func (l *StructuredLogger) Info(msg string, fields map[string]interface{}) {
	if l.level <= INFO {
		l.log(INFO, msg, fields)
	}
}

func (l *StructuredLogger) Warn(msg string, fields map[string]interface{}) {
	if l.level <= WARN {
		l.log(WARN, msg, fields)
	}
}

func (l *StructuredLogger) Error(msg string, fields map[string]interface{}) {
	if l.level <= ERROR {
		l.log(ERROR, msg, fields)
	}
}

func (l *StructuredLogger) With(fields map[string]interface{}) Logger {
	newFields := make(map[string]interface{})
	for k, v := range l.fields {
		newFields[k] = v
	}
	for k, v := range fields {
		newFields[k] = v
	}

	return &StructuredLogger{
		level:  l.level,
		fields: newFields,
		logger: l.logger,
	}
}

func (l *StructuredLogger) log(level LogLevel, msg string, fields map[string]interface{}) {
	logEntry := map[string]interface{}{
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		"level":     level.String(),
		"message":   msg,
	}

	// Add persistent fields
	for k, v := range l.fields {
		logEntry[k] = v
	}

	// Add message-specific fields
	for k, v := range fields {
		logEntry[k] = v
	}

	jsonBytes, err := json.Marshal(logEntry)
	if err != nil {
		l.logger.Printf("Failed to marshal log entry: %v", err)
		return
	}

	l.logger.Println(string(jsonBytes))
}

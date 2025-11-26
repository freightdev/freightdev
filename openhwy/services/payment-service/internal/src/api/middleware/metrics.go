// internal/adapters/http/middleware/metrics.go
package middleware

import (
    "net/http"
    "strconv"
    "time"

    "payment-service/pkg/logger"
)

type MetricsCollector interface {
    RecordHTTPRequest(method, path string, statusCode int, duration time.Duration)
    RecordPaymentProcessed(processor, status string, amount float64)
    RecordFraudCheck(riskLevel string, blocked bool)
    IncrementCounter(name string, labels map[string]string)
    RecordHistogram(name string, value float64, labels map[string]string)
    RecordGauge(name string, value float64, labels map[string]string)
}

type PrometheusMetrics struct {
    logger logger.Logger
    // In a real implementation, you'd have Prometheus client here
}

func NewPrometheusMetrics(logger logger.Logger) MetricsCollector {
    return &PrometheusMetrics{logger: logger}
}

func (pm *PrometheusMetrics) RecordHTTPRequest(method, path string, statusCode int, duration time.Duration) {
    pm.logger.Debug("HTTP request metric", map[string]interface{}{
        "method":      method,
        "path":        path,
        "status_code": statusCode,
        "duration_ms": duration.Milliseconds(),
    })
    // In real implementation: prometheus.NewHistogramVec().WithLabelValues().Observe()
}

func (pm *PrometheusMetrics) RecordPaymentProcessed(processor, status string, amount float64) {
    pm.logger.Debug("Payment processed metric", map[string]interface{}{
        "processor": processor,
        "status":    status,
        "amount":    amount,
    })
}

func (pm *PrometheusMetrics) RecordFraudCheck(riskLevel string, blocked bool) {
    pm.logger.Debug("Fraud check metric", map[string]interface{}{
        "risk_level": riskLevel,
        "blocked":    blocked,
    })
}

func (pm *PrometheusMetrics) IncrementCounter(name string, labels map[string]string) {
    pm.logger.Debug("Counter metric", map[string]interface{}{
        "name":   name,
        "labels": labels,
    })
}

func (pm *PrometheusMetrics) RecordHistogram(name string, value float64, labels map[string]string) {
    pm.logger.Debug("Histogram metric", map[string]interface{}{
        "name":   name,
        "value":  value,
        "labels": labels,
    })
}

func (pm *PrometheusMetrics) RecordGauge(name string, value float64, labels map[string]string) {
    pm.logger.Debug("Gauge metric", map[string]interface{}{
        "name":   name,
        "value":  value,
        "labels": labels,
    })
}

type MetricsMiddleware struct {
    collector MetricsCollector
}

func NewMetricsMiddleware(collector MetricsCollector) *MetricsMiddleware {
    return &MetricsMiddleware{collector: collector}
}

func (m *MetricsMiddleware) CollectMetrics(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        wrapper := &statusCapture{ResponseWriter: w, statusCode: http.StatusOK}

        next.ServeHTTP(wrapper, r)

        duration := time.Since(start)
        m.collector.RecordHTTPRequest(r.Method, r.URL.Path, wrapper.statusCode, duration)
    })
}

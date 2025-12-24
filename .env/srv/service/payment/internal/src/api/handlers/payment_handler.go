// internal/adapters/http/handlers/payment_handler.go
package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"payment-service/internal/adapters/http/dto"
	"payment-service/internal/core/domain"
	"payment-service/internal/core/ports"
	"payment-service/pkg/errors"
	"payment-service/pkg/logger"
	"payment-service/pkg/validator"

	"github.com/google/uuid"
	"github.com/gorilla/mux"
)

type PaymentHandler struct {
	paymentService ports.PaymentService
	validator      *validator.CustomValidator
	logger         logger.Logger
}

func NewPaymentHandler(
	paymentService ports.PaymentService,
	validator *validator.CustomValidator,
	logger logger.Logger,
) *PaymentHandler {
	return &PaymentHandler{
		paymentService: paymentService,
		validator:      validator,
		logger:         logger,
	}
}

func (h *PaymentHandler) CreatePayment(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	correlationID := ctx.Value("correlation_id").(string)

	var req dto.CreatePaymentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, correlationID, errors.NewValidationError(
			"INVALID_JSON",
			"Invalid JSON format",
			map[string]interface{}{"error": err.Error()},
		))
		return
	}

	if err := h.validator.Validate(req); err != nil {
		h.respondError(w, correlationID, errors.NewValidationError(
			"VALIDATION_FAILED",
			err.Error(),
			nil,
		))
		return
	}

	serviceReq := ports.CreatePaymentRequest{
		ClientID:    req.ClientID,
		MerchantID:  req.MerchantID,
		OrderID:     req.OrderID,
		Amount:      req.Amount,
		Currency:    req.Currency,
		Method:      req.Method,
		Description: req.Description,
		Metadata:    req.Metadata,
	}

	payment, err := h.paymentService.CreatePayment(ctx, serviceReq)
	if err != nil {
		h.handleServiceError(w, correlationID, err)
		return
	}

	h.logger.Info("Payment created via HTTP", map[string]interface{}{
		"correlation_id": correlationID,
		"payment_id":     payment.ID.String(),
		"client_id":      payment.ClientID,
	})

	h.respondJSON(w, http.StatusCreated, dto.ToPaymentResponse(payment))
}

func (h *PaymentHandler) ProcessPayment(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	correlationID := ctx.Value("correlation_id").(string)

	vars := mux.Vars(r)
	paymentID, err := uuid.Parse(vars["id"])
	if err != nil {
		h.respondError(w, correlationID, errors.NewValidationError(
			"INVALID_PAYMENT_ID",
			"Invalid payment ID format",
			nil,
		))
		return
	}

	var req dto.ProcessPaymentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, correlationID, errors.NewValidationError(
			"INVALID_JSON",
			"Invalid JSON format",
			map[string]interface{}{"error": err.Error()},
		))
		return
	}

	if err := h.validator.Validate(req); err != nil {
		h.respondError(w, correlationID, errors.NewValidationError(
			"VALIDATION_FAILED",
			err.Error(),
			nil,
		))
		return
	}

	serviceReq := ports.ProcessPaymentRequest{
		PaymentID:      paymentID,
		PaymentDetails: req.PaymentDetails,
	}

	payment, err := h.paymentService.ProcessPayment(ctx, serviceReq)
	if err != nil {
		h.handleServiceError(w, correlationID, err)
		return
	}

	h.logger.Info("Payment processed via HTTP", map[string]interface{}{
		"correlation_id": correlationID,
		"payment_id":     payment.ID.String(),
	})

	h.respondJSON(w, http.StatusOK, dto.ToPaymentResponse(payment))
}

func (h *PaymentHandler) RefundPayment(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	correlationID := ctx.Value("correlation_id").(string)

	vars := mux.Vars(r)
	paymentID, err := uuid.Parse(vars["id"])
	if err != nil {
		h.respondError(w, correlationID, errors.NewValidationError(
			"INVALID_PAYMENT_ID",
			"Invalid payment ID format",
			nil,
		))
		return
	}

	var req dto.RefundPaymentRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondError(w, correlationID, errors.NewValidationError(
			"INVALID_JSON",
			"Invalid JSON format",
			map[string]interface{}{"error": err.Error()},
		))
		return
	}

	if err := h.validator.Validate(req); err != nil {
		h.respondError(w, correlationID, errors.NewValidationError(
			"VALIDATION_FAILED",
			err.Error(),
			nil,
		))
		return
	}

	serviceReq := ports.RefundPaymentRequest{
		PaymentID: paymentID,
		Amount:    req.Amount,
		Reason:    req.Reason,
	}

	payment, err := h.paymentService.RefundPayment(ctx, serviceReq)
	if err != nil {
		h.handleServiceError(w, correlationID, err)
		return
	}

	h.logger.Info("Payment refunded via HTTP", map[string]interface{}{
		"correlation_id": correlationID,
		"payment_id":     payment.ID.String(),
		"refund_amount":  req.Amount.String(),
	})

	h.respondJSON(w, http.StatusOK, dto.ToPaymentResponse(payment))
}

func (h *PaymentHandler) GetPayment(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	correlationID := ctx.Value("correlation_id").(string)

	vars := mux.Vars(r)
	paymentID, err := uuid.Parse(vars["id"])
	if err != nil {
		h.respondError(w, correlationID, errors.NewValidationError(
			"INVALID_PAYMENT_ID",
			"Invalid payment ID format",
			nil,
		))
		return
	}

	payment, err := h.paymentService.GetPayment(ctx, paymentID)
	if err != nil {
		h.handleServiceError(w, correlationID, err)
		return
	}

	h.respondJSON(w, http.StatusOK, dto.ToPaymentResponse(payment))
}

func (h *PaymentHandler) ListPayments(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	correlationID := ctx.Value("correlation_id").(string)

	clientID := r.URL.Query().Get("client_id")
	if clientID == "" {
		h.respondError(w, correlationID, errors.NewValidationError(
			"MISSING_CLIENT_ID",
			"client_id query parameter is required",
			nil,
		))
		return
	}

	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	if limit <= 0 {
		limit = 50
	}

	offset, _ := strconv.Atoi(r.URL.Query().Get("offset"))
	if offset < 0 {
		offset = 0
	}

	payments, err := h.paymentService.ListPayments(ctx, clientID, limit, offset)
	if err != nil {
		h.handleServiceError(w, correlationID, err)
		return
	}

	response := dto.ToPaymentListResponse(payments, len(payments), limit, offset)
	h.respondJSON(w, http.StatusOK, response)
}

func (h *PaymentHandler) CancelPayment(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	correlationID := ctx.Value("correlation_id").(string)

	vars := mux.Vars(r)
	paymentID, err := uuid.Parse(vars["id"])
	if err != nil {
		h.respondError(w, correlationID, errors.NewValidationError(
			"INVALID_PAYMENT_ID",
			"Invalid payment ID format",
			nil,
		))
		return
	}

	if err := h.paymentService.CancelPayment(ctx, paymentID); err != nil {
		h.handleServiceError(w, correlationID, err)
		return
	}

	h.logger.Info("Payment cancelled via HTTP", map[string]interface{}{
		"correlation_id": correlationID,
		"payment_id":     paymentID.String(),
	})

	w.WriteHeader(http.StatusNoContent)
}

func (h *PaymentHandler) handleServiceError(w http.ResponseWriter, correlationID string, err error) {
	if domainErr, ok := err.(domain.DomainError); ok {
		var appErr *errors.AppError
		switch domainErr.Code {
		case "PAYMENT_NOT_FOUND":
			appErr = errors.NewNotFoundError(domainErr.Code, domainErr.Message)
		case "PAYMENT_ALREADY_PROCESSED":
			appErr = errors.NewConflictError(domainErr.Code, domainErr.Message)
		default:
			appErr = errors.NewValidationError(domainErr.Code, domainErr.Message, nil)
		}
		h.respondError(w, correlationID, appErr)
		return
	}

	h.logger.Error("Unexpected service error", map[string]interface{}{
		"correlation_id": correlationID,
		"error":          err.Error(),
	})

	h.respondError(w, correlationID, errors.NewInternalError(
		"INTERNAL_ERROR",
		"An unexpected error occurred",
		err,
	))
}

func (h *PaymentHandler) respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func (h *PaymentHandler) respondError(w http.ResponseWriter, correlationID string, err *errors.AppError) {
	errorResponse := dto.ErrorResponse{
		Type:      string(err.Type),
		Code:      err.Code,
		Message:   err.Message,
		Details:   err.Details,
		RequestID: correlationID,
		Timestamp: time.Now().UTC(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(err.HTTPStatus)
	json.NewEncoder(w).Encode(errorResponse)
}

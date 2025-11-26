// pkg/validator/validator.go
package validator

import (
	"fmt"
	"reflect"
	"strings"

	"payment-service/internal/core/domain"

	"github.com/go-playground/validator/v10"
	"github.com/shopspring/decimal"
)

type CustomValidator struct {
	validator *validator.Validate
}

func New() *CustomValidator {
	v := validator.New()

	// Register custom validations
	v.RegisterValidation("currency", validateCurrency)
	v.RegisterValidation("payment_method", validatePaymentMethod)
	v.RegisterValidation("decimal_gt", validateDecimalGreaterThan)
	v.RegisterValidation("uuid_required", validateUUIDRequired)

	// Use JSON tag names in error messages
	v.RegisterTagNameFunc(func(fld reflect.StructField) string {
		name := strings.SplitN(fld.Tag.Get("json"), ",", 2)[0]
		if name == "-" {
			return ""
		}
		return name
	})

	return &CustomValidator{validator: v}
}

func (cv *CustomValidator) Validate(i interface{}) error {
	if err := cv.validator.Struct(i); err != nil {
		return cv.formatValidationErrors(err)
	}
	return nil
}

func (cv *CustomValidator) formatValidationErrors(err error) error {
	if validationErrors, ok := err.(validator.ValidationErrors); ok {
		var messages []string
		for _, validationError := range validationErrors {
			message := cv.getErrorMessage(validationError)
			messages = append(messages, message)
		}
		return fmt.Errorf("validation failed: %s", strings.Join(messages, "; "))
	}
	return err
}

func (cv *CustomValidator) getErrorMessage(err validator.FieldError) string {
	field := err.Field()

	switch err.Tag() {
	case "required":
		return fmt.Sprintf("%s is required", field)
	case "email":
		return fmt.Sprintf("%s must be a valid email", field)
	case "min":
		return fmt.Sprintf("%s must be at least %s characters", field, err.Param())
	case "max":
		return fmt.Sprintf("%s must be at most %s characters", field, err.Param())
	case "gt":
		return fmt.Sprintf("%s must be greater than %s", field, err.Param())
	case "gte":
		return fmt.Sprintf("%s must be greater than or equal to %s", field, err.Param())
	case "lt":
		return fmt.Sprintf("%s must be less than %s", field, err.Param())
	case "lte":
		return fmt.Sprintf("%s must be less than or equal to %s", field, err.Param())
	case "currency":
		return fmt.Sprintf("%s must be a valid currency code", field)
	case "payment_method":
		return fmt.Sprintf("%s must be a valid payment method", field)
	case "decimal_gt":
		return fmt.Sprintf("%s must be greater than %s", field, err.Param())
	case "uuid_required":
		return fmt.Sprintf("%s must be a valid UUID", field)
	default:
		return fmt.Sprintf("%s is invalid", field)
	}
}

// Custom validation functions
func validateCurrency(fl validator.FieldLevel) bool {
	currency := fl.Field().String()
	switch domain.Currency(currency) {
	case domain.CurrencyUSD, domain.CurrencyEUR, domain.CurrencyGBP:
		return true
	default:
		return false
	}
}

func validatePaymentMethod(fl validator.FieldLevel) bool {
	method := fl.Field().String()
	switch domain.PaymentMethod(method) {
	case domain.PaymentMethodCard, domain.PaymentMethodBank,
		domain.PaymentMethodWallet, domain.PaymentMethodCrypto:
		return true
	default:
		return false
	}
}

func validateDecimalGreaterThan(fl validator.FieldLevel) bool {
	field := fl.Field()
	param := fl.Param()

	// Handle decimal.Decimal type
	if field.Type() == reflect.TypeOf(decimal.Decimal{}) {
		value := field.Interface().(decimal.Decimal)
		threshold, err := decimal.NewFromString(param)
		if err != nil {
			return false
		}
		return value.GreaterThan(threshold)
	}

	return false
}

func validateUUIDRequired(fl validator.FieldLevel) bool {
	value := fl.Field().String()
	return value != "" && len(value) == 36
}

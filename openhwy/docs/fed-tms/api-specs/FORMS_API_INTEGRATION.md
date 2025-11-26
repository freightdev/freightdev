# Forms API Integration Guide

This document describes the form submission system and API integration setup for the FED-TMS Forms Section.

## Overview

The Forms Section includes 16 comprehensive trucking forms organized into 5 categories:
- **Dispatcher Agreements** (5 forms)
- **Carrier & Broker Forms** (3 forms)
- **Operational Forms** (3 forms)
- **Financial & Tax Forms** (3 forms)
- **Compliance Documents** (3 forms)

All forms are integrated with custom React hooks that handle API submissions and error management.

## Form Submission Hooks

Located at: `/lib/hooks/useForms.ts`

### Available Hooks

#### 1. useDispatcherAgreementForm()
Handles submission of dispatcher agreement forms:
- Full Dispatcher Agreement
- Half Dispatcher Agreement
- Load Finder Agreement
- Paperwork Only Agreement

**Usage:**
```typescript
const { submitForm, loading, error } = useDispatcherAgreementForm()
await submitForm(formData)
```

**API Endpoint:** `POST /api/forms/dispatcher-agreements`

---

#### 2. useCarrierForm()
Handles carrier agreement and profile submissions.

**Methods:**
- `submitCarrierAgreement(formData)` → POST `/api/forms/carrier-agreements`
- `submitCarrierProfile(formData)` → POST `/api/forms/carrier-profiles`

**Usage:**
```typescript
const { submitCarrierAgreement, submitCarrierProfile, loading, error } = useCarrierForm()
```

---

#### 3. useBrokerAgreementForm()
Handles broker agreement submissions.

**API Endpoint:** `POST /api/forms/broker-agreements`

**Usage:**
```typescript
const { submitForm, loading, error } = useBrokerAgreementForm()
```

---

#### 4. useOperationalForm()
Handles operational document submissions (BOL, POD, Rate Confirmation).

**Methods:**
- `submitBOL(formData)` → POST `/api/forms/bill-of-lading`
- `submitPOD(formData)` → POST `/api/forms/proof-of-delivery`
- `submitRateConfirmation(formData)` → POST `/api/forms/rate-confirmations`

**Usage:**
```typescript
const { submitBOL, submitPOD, submitRateConfirmation, loading, error } = useOperationalForm()
```

---

#### 5. useFinancialForm()
Handles financial and tax form submissions.

**Methods:**
- `submitCreditCardAuth(formData)` → POST `/api/forms/credit-card-authorizations`
- `submitW9(formData)` → POST `/api/forms/w9`
- `submitACHAuth(formData)` → POST `/api/forms/ach-authorizations`

**Usage:**
```typescript
const { submitCreditCardAuth, submitW9, submitACHAuth, loading, error } = useFinancialForm()
```

---

#### 6. useComplianceForm()
Handles compliance and insurance document submissions.

**Methods:**
- `submitCOI(formData)` → POST `/api/forms/certificates-of-insurance`
- `submitMCAuthority(formData)` → POST `/api/forms/mc-authority`
- `submitInsuranceRequirements(formData)` → POST `/api/forms/insurance-requirements`

**Usage:**
```typescript
const { submitCOI, submitMCAuthority, submitInsuranceRequirements, loading, error } = useComplianceForm()
```

---

#### 7. useFormSubmission(formType: string)
Generic hook for any form type.

**Usage:**
```typescript
const { submit, loading, error } = useFormSubmission('dispatcher-agreements')
await submit(formData)
```

---

## Hook Return Values

All hooks return:
```typescript
{
  submit/submitX: async (formData: any) => Promise<FormSubmissionResponse>,
  loading: boolean,              // True while submitting
  error: FormError | null        // Error object if submission fails
}
```

### FormSubmissionResponse
```typescript
{
  id: string                     // Unique form submission ID
  formType: string              // Type of form submitted
  status: 'draft' | 'submitted' | 'approved' | 'rejected'
  createdAt: string             // ISO timestamp
  updatedAt: string             // ISO timestamp
}
```

### FormError
```typescript
{
  field?: string               // Optional field name
  message: string             // Error message
}
```

---

## Form Integration Examples

### Example 1: Carrier Agreement Packet Form

**File:** `/app/(dashboard)/forms/carrier-agreement-packet/page.tsx`

```typescript
'use client'

import { useRouter } from 'next/navigation'
import { useCarrierForm } from '@/lib/hooks'

export default function CarrierAgreementPacketPage() {
  const router = useRouter()
  const { submitCarrierAgreement, loading, error } = useCarrierForm()
  const [formData, setFormData] = useState({...})

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await submitCarrierAgreement(formData)
      router.push('/dashboard/forms')
    } catch (err) {
      // Error handled by hook
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
      <button type="submit" disabled={loading}>
        {loading ? 'Submitting...' : 'Submit'}
      </button>
    </form>
  )
}
```

---

## API Endpoint Requirements

Each form hook expects corresponding backend API endpoints. Here's what needs to be implemented:

### Request Format
```typescript
POST /api/forms/{formType}
Content-Type: application/json

{
  // Form data fields specific to the form type
}
```

### Success Response (200 OK)
```json
{
  "id": "form_123abc",
  "formType": "carrier-agreements",
  "status": "submitted",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z"
}
```

### Error Response (4xx/5xx)
```json
{
  "message": "Field 'carrierName' is required",
  "field": "carrierName"
}
```

---

## Security Considerations

### Sensitive Data Handling

1. **Credit Card Authorization Forms**
   - Never send full card numbers in formData
   - Implement card tokenization before submission
   - Use PCI-DSS compliant payment processor

2. **ACH Authorization Forms**
   - Encrypt bank account information
   - Implement secure bank account verification
   - Store only last 4 digits in logs

3. **Tax Forms (W-9, EIN, SSN)**
   - Mark sensitive fields with security notice
   - Implement encryption at rest
   - Restrict access to authorized personnel

### Hook Security Features
- Error handling prevents sensitive data from leaking in error messages
- Automatic toast notifications for user feedback
- No console logging of sensitive form data (in production)

---

## Form Data Validation

### Client-Side Validation
Add validation to form components before submission:

```typescript
const validateForm = (formData) => {
  const errors: Record<string, string> = {}

  if (!formData.carrierName) {
    errors.carrierName = 'Carrier name is required'
  }

  if (!formData.contactEmail || !formData.contactEmail.includes('@')) {
    errors.contactEmail = 'Valid email is required'
  }

  return errors
}

const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault()
  const errors = validateForm(formData)

  if (Object.keys(errors).length > 0) {
    Object.entries(errors).forEach(([field, message]) => {
      addToast(message, 'error')
    })
    return
  }

  await submitCarrierAgreement(formData)
}
```

### Server-Side Validation
API endpoints must implement comprehensive validation:
- Required field checks
- Format validation (phone, email, date)
- Business logic validation (insurance limits, rates)
- Duplicate prevention

---

## Form Status Management

Forms can be submitted with different statuses:
- `draft`: Form saved but not submitted
- `submitted`: Form submitted for review
- `approved`: Form approved by administrator
- `rejected`: Form rejected with feedback

### Draft Saving
To implement draft saving, modify hooks:

```typescript
const saveDraft = async (formData: any) => {
  const response = await fetch('/api/forms/{type}/draft', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ...formData, status: 'draft' }),
  })
  return response.json()
}
```

---

## PDF Generation & Download

Forms include a "Download PDF" button. To implement:

1. **Frontend:** Trigger PDF download
```typescript
const downloadPDF = async () => {
  const response = await fetch(`/api/forms/${formType}/${formId}/pdf`)
  const blob = await response.blob()
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${formType}-${formId}.pdf`
  a.click()
}
```

2. **Backend:** Generate PDF from form data using library like:
   - PDFKit
   - Puppeteer
   - ReportLab

---

## Form Listing & History

To implement form history/listing:

```typescript
// API Endpoint
GET /api/forms?type={formType}&userId={userId}&status={status}

// Response
{
  "data": [
    {
      "id": "form_123",
      "formType": "carrier-agreements",
      "status": "submitted",
      "createdAt": "2024-01-15T10:30:00Z",
      "submittedBy": "user@example.com"
    }
  ],
  "total": 42,
  "page": 1,
  "pageSize": 10
}
```

---

## Error Handling Best Practices

1. **Display user-friendly messages** via toast notifications
2. **Log detailed errors** on server for debugging
3. **Distinguish between client and server errors**
4. **Implement retry logic** for transient failures
5. **Prevent duplicate submissions** with disabled button state

---

## Testing

### Unit Tests for Hooks
```typescript
import { renderHook, act } from '@testing-library/react'
import { useCarrierForm } from '@/lib/hooks'

test('submitCarrierAgreement success', async () => {
  const { result } = renderHook(() => useCarrierForm())

  const formData = {
    carrierName: 'Test Carrier',
    // ...
  }

  await act(async () => {
    const response = await result.current.submitCarrierAgreement(formData)
    expect(response.status).toBe('submitted')
  })
})
```

### Integration Tests
Test complete form flow:
1. Fill form fields
2. Submit form
3. Verify API call
4. Check success response
5. Verify redirect/toast

---

## Future Enhancements

1. **Form Versioning**: Support multiple form versions with migration logic
2. **E-Signature Integration**: DocuSign/HelloSign integration for digital signatures
3. **Form Templates**: Save and reuse form templates with pre-filled data
4. **Bulk Operations**: Submit multiple forms or batch process
5. **Audit Trail**: Complete history of form changes and submissions
6. **Conditional Fields**: Show/hide fields based on form selections
7. **Field Dependencies**: Automatic calculations and cross-field validation
8. **Multi-step Forms**: Break long forms into multiple pages
9. **Offline Support**: Queue form submissions when offline
10. **Form Analytics**: Track form completion rates and field dropout

---

## Support & Documentation

For questions or issues with form integration:
1. Check the hook implementation in `/lib/hooks/useForms.ts`
2. Review integration examples in individual form pages
3. Check API endpoint implementations in `/api/forms/*`
4. Review error logs for detailed error information

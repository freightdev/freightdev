import { useState } from 'react'
import { useToast } from '@/lib/contexts/ToastContext'

export interface FormSubmissionResponse {
  id: string
  formType: string
  status: 'draft' | 'submitted' | 'approved' | 'rejected'
  createdAt: string
  updatedAt: string
}

export interface FormError {
  field?: string
  message: string
}

/**
 * Hook for submitting dispatcher agreement forms
 */
export function useDispatcherAgreementForm() {
  const { addToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<FormError | null>(null)

  const submitForm = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/dispatcher-agreements', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit form')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Dispatcher agreement submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  return { submitForm, loading, error }
}

/**
 * Hook for submitting carrier forms
 */
export function useCarrierForm() {
  const { addToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<FormError | null>(null)

  const submitCarrierAgreement = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/carrier-agreements', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit carrier agreement')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Carrier agreement submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  const submitCarrierProfile = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/carrier-profiles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit carrier profile')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Carrier profile submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  return { submitCarrierAgreement, submitCarrierProfile, loading, error }
}

/**
 * Hook for submitting broker agreements
 */
export function useBrokerAgreementForm() {
  const { addToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<FormError | null>(null)

  const submitForm = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/broker-agreements', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit broker agreement')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Broker agreement submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  return { submitForm, loading, error }
}

/**
 * Hook for submitting operational forms (BOL, POD, etc.)
 */
export function useOperationalForm() {
  const { addToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<FormError | null>(null)

  const submitBOL = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/bill-of-lading', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit Bill of Lading')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Bill of Lading submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  const submitPOD = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/proof-of-delivery', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit Proof of Delivery')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Proof of Delivery submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  const submitRateConfirmation = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/rate-confirmations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit rate confirmation')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Rate confirmation submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  return { submitBOL, submitPOD, submitRateConfirmation, loading, error }
}

/**
 * Hook for submitting financial and tax forms
 */
export function useFinancialForm() {
  const { addToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<FormError | null>(null)

  const submitCreditCardAuth = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      // Note: In production, this would tokenize the card before sending
      const response = await fetch('/api/forms/credit-card-authorizations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit credit card authorization')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Credit card authorization submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  const submitW9 = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/w9', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit Form W-9')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Form W-9 submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  const submitACHAuth = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/ach-authorizations', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit ACH authorization')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('ACH authorization submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  return { submitCreditCardAuth, submitW9, submitACHAuth, loading, error }
}

/**
 * Hook for submitting compliance and insurance forms
 */
export function useComplianceForm() {
  const { addToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<FormError | null>(null)

  const submitCOI = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/certificates-of-insurance', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit Certificate of Insurance')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Certificate of Insurance submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  const submitMCAuthority = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/mc-authority', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit MC Authority')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('MC Authority submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  const submitInsuranceRequirements = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/forms/insurance-requirements', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to submit Insurance Requirements')
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Insurance Requirements submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  return { submitCOI, submitMCAuthority, submitInsuranceRequirements, loading, error }
}

/**
 * Generic form submission hook for any form type
 */
export function useFormSubmission(formType: string) {
  const { addToast } = useToast()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<FormError | null>(null)

  const submit = async (formData: any) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/forms/${formType}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || `Failed to submit ${formType}`)
      }

      const data: FormSubmissionResponse = await response.json()
      addToast('Form submitted successfully', 'success')
      return data
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred'
      setError({ message: errorMessage })
      addToast(errorMessage, 'error')
      throw err
    } finally {
      setLoading(false)
    }
  }

  return { submit, loading, error }
}

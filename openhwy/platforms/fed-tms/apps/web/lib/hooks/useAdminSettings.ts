import { useState, useEffect } from 'react'

export interface AdminSettings {
  general: {
    applicationName: string
    applicationLogo?: string
    supportEmail: string
    defaultCurrency: string
    defaultLocale: string
    timezone: string
  }
  business: {
    defaultCommissionRate: number
    minInsuranceAmount: number
    maxCommissionRate: number
    operatingHours: {
      dayOfWeek: string
      startTime: string
      endTime: string
    }[]
    serviceAreas: string[]
  }
  security: {
    passwordMinLength: number
    passwordRequireSpecialChars: boolean
    sessionTimeoutMinutes: number
    enableTwoFactor: boolean
    maxLoginAttempts: number
  }
  integrations: {
    emailProvider?: string
    smsProvider?: string
    paymentProvider?: string
    externalApiEndpoint?: string
  }
}

/**
 * Hook for fetching admin settings
 */
export function useAdminSettings(section: keyof AdminSettings | 'all' = 'all') {
  const [settings, setSettings] = useState<AdminSettings | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchSettings = async () => {
      try {
        setLoading(true)
        setError(null)

        const url = section === 'all' ? '/api/admin/settings' : `/api/admin/settings/${section}`
        const response = await fetch(url)

        if (!response.ok) {
          throw new Error('Failed to fetch settings')
        }

        const data = await response.json()
        setSettings(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchSettings()
  }, [section])

  return { settings, loading, error }
}

/**
 * Hook for updating admin settings
 */
export function useUpdateAdminSettings() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const updateGeneralSettings = async (data: AdminSettings['general']) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/admin/settings/general', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to update general settings')
      }

      return await response.json()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      throw err
    } finally {
      setLoading(false)
    }
  }

  const updateBusinessSettings = async (data: AdminSettings['business']) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/admin/settings/business', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to update business settings')
      }

      return await response.json()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      throw err
    } finally {
      setLoading(false)
    }
  }

  const updateSecuritySettings = async (data: AdminSettings['security']) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/admin/settings/security', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to update security settings')
      }

      return await response.json()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      throw err
    } finally {
      setLoading(false)
    }
  }

  const updateIntegrationSettings = async (data: AdminSettings['integrations']) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/admin/settings/integrations', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to update integration settings')
      }

      return await response.json()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      throw err
    } finally {
      setLoading(false)
    }
  }

  return { updateGeneralSettings, updateBusinessSettings, updateSecuritySettings, updateIntegrationSettings, loading, error }
}

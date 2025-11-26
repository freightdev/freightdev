import { useState, useEffect, useCallback } from 'react'
import { useApi } from './useApi'
import type { Driver } from './useDrivers'

interface DriverDetailResponse {
  driver: Driver & {
    // Extended fields for detail view
    address?: string
    emergency_contact?: string
    emergency_phone?: string
    certifications?: Array<{
      name: string
      number: string
      expiry_date: string
      status: 'valid' | 'expired' | 'expiring_soon'
    }>
    recent_loads?: Array<{
      id: string
      reference: string
      origin: string
      destination: string
      status: string
      rate: number
    }>
    performance_metrics?: {
      on_time_delivery_rate: number
      vehicle_utilization_rate: number
      total_distance: number
      total_earnings: number
    }
    documents?: Array<{
      id: string
      name: string
      type: string
      url: string
      uploaded_at: string
      verified: boolean
    }>
  }
}

interface UseDriverOptions {
  autoFetch?: boolean
}

export function useDriver(id: string | undefined, options: UseDriverOptions = {}) {
  const { autoFetch = true } = options

  const api = useApi()
  const [driver, setDriver] = useState<DriverDetailResponse['driver'] | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchDriver = useCallback(async () => {
    if (!id) {
      setError('No driver ID provided')
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await api.get<DriverDetailResponse>(`/drivers/${id}`)

      if (response.error) {
        setError(response.error)
        setDriver(null)
        return
      }

      const data = response.data as DriverDetailResponse
      setDriver(data.driver || null)
    } catch (err) {
      const errorMessage =
        err instanceof Error ? err.message : 'Failed to fetch driver'
      setError(errorMessage)
      setDriver(null)
    } finally {
      setLoading(false)
    }
  }, [api, id])

  useEffect(() => {
    if (autoFetch && id) {
      fetchDriver()
    }
  }, [fetchDriver, autoFetch, id])

  const refetch = useCallback(() => {
    fetchDriver()
  }, [fetchDriver])

  return {
    driver,
    loading,
    error,
    refetch,
  }
}

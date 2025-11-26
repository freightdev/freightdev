import { useState, useEffect, useCallback } from 'react'
import { useApi } from './useApi'
import type { Load } from './useLoads'

interface LoadDetailResponse {
  load: Load & {
    // Extended fields for detail view
    pickup_time?: string
    delivery_deadline?: string
    cargo_type?: string
    cargo_weight?: string
    cargo_dimensions?: string
    special_notes?: string
    tracking_history?: Array<{
      id: string
      status: string
      timestamp: string
      location?: string
      notes?: string
    }>
    driver_details?: {
      id: string
      name: string
      vehicle: string
      license_plate: string
    }
    documents?: Array<{
      id: string
      name: string
      type: string
      url: string
      uploaded_at: string
    }>
    payment_status?: 'pending' | 'invoiced' | 'paid'
    invoice_id?: string
  }
}

interface UseLoadOptions {
  autoFetch?: boolean
}

export function useLoad(id: string | undefined, options: UseLoadOptions = {}) {
  const { autoFetch = true } = options

  const api = useApi()
  const [load, setLoad] = useState<LoadDetailResponse['load'] | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchLoad = useCallback(async () => {
    if (!id) {
      setError('No load ID provided')
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await api.get<LoadDetailResponse>(`/loads/${id}`)

      if (response.error) {
        setError(response.error)
        setLoad(null)
        return
      }

      const data = response.data as LoadDetailResponse
      setLoad(data.load || null)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch load'
      setError(errorMessage)
      setLoad(null)
    } finally {
      setLoading(false)
    }
  }, [api, id])

  useEffect(() => {
    if (autoFetch && id) {
      fetchLoad()
    }
  }, [fetchLoad, autoFetch, id])

  const refetch = useCallback(() => {
    fetchLoad()
  }, [fetchLoad])

  return {
    load,
    loading,
    error,
    refetch,
  }
}

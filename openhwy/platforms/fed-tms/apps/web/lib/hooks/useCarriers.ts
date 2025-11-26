import { useState, useEffect } from 'react'

export interface Carrier {
  id: string
  name: string
  mcNumber: string
  dotNumber: string
  email: string
  phone: string
  status: 'approved' | 'pending' | 'suspended' | 'inactive'
  safetyRating: 'satisfactory' | 'conditional' | 'unsatisfactory' | 'not_rated'
  insuranceStatus: 'current' | 'expiring' | 'expired'
  activeSince: string
  totalLoads: number
  totalRevenue: number
  acceptanceRate: number
  contactPerson: string
  contactEmail: string
  contactPhone: string
}

export interface CarrierFormData {
  name: string
  mcNumber: string
  dotNumber?: string
  email: string
  phone: string
  contactPerson: string
  contactEmail: string
  contactPhone: string
  safetyRating?: 'satisfactory' | 'conditional' | 'unsatisfactory' | 'not_rated'
}

export interface CarriersResponse {
  data: Carrier[]
  total: number
  page: number
  pageSize: number
}

/**
 * Hook for fetching carrier list with pagination and filtering
 */
export function useCarriers(page = 1, pageSize = 20, filters?: { status?: string; safetyRating?: string }) {
  const [carriers, setCarriers] = useState<Carrier[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [total, setTotal] = useState(0)

  useEffect(() => {
    const fetchCarriers = async () => {
      try {
        setLoading(true)
        setError(null)

        const queryParams = new URLSearchParams({
          page: page.toString(),
          pageSize: pageSize.toString(),
        })

        if (filters?.status) queryParams.append('status', filters.status)
        if (filters?.safetyRating) queryParams.append('safetyRating', filters.safetyRating)

        const response = await fetch(`/api/admin/carriers?${queryParams}`)

        if (!response.ok) {
          throw new Error('Failed to fetch carriers')
        }

        const data: CarriersResponse = await response.json()
        setCarriers(data.data)
        setTotal(data.total)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchCarriers()
  }, [page, pageSize, filters])

  return { carriers, loading, error, total }
}

/**
 * Hook for fetching single carrier details
 */
export function useCarrier(carrierId: string | null) {
  const [carrier, setCarrier] = useState<Carrier | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!carrierId) {
      setCarrier(null)
      setLoading(false)
      return
    }

    const fetchCarrier = async () => {
      try {
        setLoading(true)
        setError(null)

        const response = await fetch(`/api/admin/carriers/${carrierId}`)

        if (!response.ok) {
          throw new Error('Failed to fetch carrier')
        }

        const data: Carrier = await response.json()
        setCarrier(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchCarrier()
  }, [carrierId])

  return { carrier, loading, error }
}

/**
 * Hook for managing carrier creation/update/approval
 */
export function useCarrierManagement() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const createCarrier = async (formData: CarrierFormData) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/admin/carriers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to create carrier')
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

  const updateCarrier = async (carrierId: string, formData: Partial<CarrierFormData>) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/admin/carriers/${carrierId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to update carrier')
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

  const approveCarrier = async (carrierId: string) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/admin/carriers/${carrierId}/approve`, {
        method: 'POST',
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to approve carrier')
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

  const rejectCarrier = async (carrierId: string, reason: string) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/admin/carriers/${carrierId}/reject`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason }),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to reject carrier')
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

  const changeCarrierStatus = async (carrierId: string, status: 'approved' | 'pending' | 'suspended' | 'inactive') => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/admin/carriers/${carrierId}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to update carrier status')
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

  return { createCarrier, updateCarrier, approveCarrier, rejectCarrier, changeCarrierStatus, loading, error }
}

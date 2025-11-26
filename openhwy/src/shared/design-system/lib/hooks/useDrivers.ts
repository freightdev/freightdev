import { useState, useEffect, useCallback } from 'react'
import { useApi } from './useApi'

export interface Driver {
  id: string
  user_id: string
  license: string
  status: 'active' | 'inactive' | 'on_leave' | 'suspended'
  rating: number
  completed_loads: number
  phone?: string
  email?: string
  vehicle?: string
  license_plate?: string
  created_at: string
  updated_at: string
  // Extended fields from user
  first_name?: string
  last_name?: string
  name?: string
}

interface DriversResponse {
  drivers: Driver[]
  total: number
  page: number
  limit: number
}

interface UseDriversOptions {
  page?: number
  limit?: number
  search?: string
  status?: string
  autoFetch?: boolean
}

export function useDrivers(options: UseDriversOptions = {}) {
  const {
    page = 1,
    limit = 10,
    search = '',
    status = 'all',
    autoFetch = true,
  } = options

  const api = useApi()
  const [drivers, setDrivers] = useState<Driver[]>([])
  const [total, setTotal] = useState(0)
  const [currentPage, setCurrentPage] = useState(page)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchDrivers = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const queryParams = new URLSearchParams({
        page: currentPage.toString(),
        limit: limit.toString(),
      })

      if (search) {
        queryParams.append('search', search)
      }

      if (status && status !== 'all') {
        queryParams.append('status', status)
      }

      const response = await api.get<DriversResponse>(
        `/drivers?${queryParams.toString()}`
      )

      if (response.error) {
        setError(response.error)
        setDrivers([])
        setTotal(0)
        return
      }

      const data = response.data as DriversResponse
      setDrivers(data.drivers || [])
      setTotal(data.total || 0)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch drivers'
      setError(errorMessage)
      setDrivers([])
    } finally {
      setLoading(false)
    }
  }, [api, currentPage, limit, search, status])

  useEffect(() => {
    if (autoFetch) {
      fetchDrivers()
    }
  }, [fetchDrivers, autoFetch])

  const refetch = useCallback(() => {
    fetchDrivers()
  }, [fetchDrivers])

  const goToPage = useCallback((newPage: number) => {
    setCurrentPage(newPage)
  }, [])

  return {
    drivers,
    total,
    currentPage,
    loading,
    error,
    refetch,
    goToPage,
    hasNextPage: currentPage * limit < total,
    hasPrevPage: currentPage > 1,
  }
}

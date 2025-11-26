import { useState, useEffect, useCallback } from 'react'
import { useApi } from './useApi'

export interface Load {
  id: string
  reference: string
  driver_id?: string
  status: 'pending' | 'in_transit' | 'delivered' | 'cancelled'
  origin: string
  destination: string
  distance?: number
  rate: number
  weight?: number
  cargo_type?: string
  progress?: number
  eta?: string
  created_at: string
  updated_at: string
  driver_name?: string
  vehicle?: string
}

interface LoadsResponse {
  loads: Load[]
  total: number
  page: number
  limit: number
}

interface UseLoadsOptions {
  page?: number
  limit?: number
  search?: string
  status?: string
  autoFetch?: boolean
}

export function useLoads(options: UseLoadsOptions = {}) {
  const {
    page = 1,
    limit = 10,
    search = '',
    status = 'all',
    autoFetch = true,
  } = options

  const api = useApi()
  const [loads, setLoads] = useState<Load[]>([])
  const [total, setTotal] = useState(0)
  const [currentPage, setCurrentPage] = useState(page)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchLoads = useCallback(async () => {
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

      const response = await api.get<LoadsResponse>(
        `/loads?${queryParams.toString()}`
      )

      if (response.error) {
        setError(response.error)
        setLoads([])
        setTotal(0)
        return
      }

      const data = response.data as LoadsResponse
      setLoads(data.loads || [])
      setTotal(data.total || 0)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch loads'
      setError(errorMessage)
      setLoads([])
    } finally {
      setLoading(false)
    }
  }, [api, currentPage, limit, search, status])

  useEffect(() => {
    if (autoFetch) {
      fetchLoads()
    }
  }, [fetchLoads, autoFetch])

  const refetch = useCallback(() => {
    fetchLoads()
  }, [fetchLoads])

  const goToPage = useCallback((newPage: number) => {
    setCurrentPage(newPage)
  }, [])

  return {
    loads,
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

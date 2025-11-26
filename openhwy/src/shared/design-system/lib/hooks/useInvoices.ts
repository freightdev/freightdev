import { useState, useEffect, useCallback } from 'react'
import { useApi } from './useApi'

export interface Invoice {
  id: string
  number: string
  driver_id?: string
  amount: number
  paid_amount: number
  remaining_amount: number
  status: 'draft' | 'pending' | 'partial' | 'paid' | 'cancelled'
  due_date: string
  created_at: string
  updated_at: string
  driver_name?: string
  load_ids?: string[]
}

interface InvoicesResponse {
  invoices: Invoice[]
  total: number
  page: number
  limit: number
}

interface UseInvoicesOptions {
  page?: number
  limit?: number
  search?: string
  status?: string
  autoFetch?: boolean
}

export function useInvoices(options: UseInvoicesOptions = {}) {
  const {
    page = 1,
    limit = 10,
    search = '',
    status = 'all',
    autoFetch = true,
  } = options

  const api = useApi()
  const [invoices, setInvoices] = useState<Invoice[]>([])
  const [total, setTotal] = useState(0)
  const [currentPage, setCurrentPage] = useState(page)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchInvoices = useCallback(async () => {
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

      const response = await api.get<InvoicesResponse>(
        `/invoices?${queryParams.toString()}`
      )

      if (response.error) {
        setError(response.error)
        setInvoices([])
        setTotal(0)
        return
      }

      const data = response.data as InvoicesResponse
      setInvoices(data.invoices || [])
      setTotal(data.total || 0)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch invoices'
      setError(errorMessage)
      setInvoices([])
    } finally {
      setLoading(false)
    }
  }, [api, currentPage, limit, search, status])

  useEffect(() => {
    if (autoFetch) {
      fetchInvoices()
    }
  }, [fetchInvoices, autoFetch])

  const refetch = useCallback(() => {
    fetchInvoices()
  }, [fetchInvoices])

  const goToPage = useCallback((newPage: number) => {
    setCurrentPage(newPage)
  }, [])

  return {
    invoices,
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

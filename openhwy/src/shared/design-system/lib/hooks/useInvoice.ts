import { useState, useEffect, useCallback } from 'react'
import { useApi } from './useApi'
import type { Invoice } from './useInvoices'

interface InvoiceDetailResponse {
  invoice: Invoice & {
    // Extended fields for detail view
    line_items?: Array<{
      id: string
      load_id: string
      load_reference: string
      route: string
      distance: number
      rate: number
      subtotal: number
    }>
    subtotal?: number
    tax?: number
    tax_rate?: number
    total?: number
    payment_history?: Array<{
      id: string
      amount: number
      payment_method: 'bank_transfer' | 'check' | 'credit_card' | 'cash'
      paid_at: string
      notes?: string
    }>
    created_at?: string
    updated_at?: string
  }
}

interface UseInvoiceOptions {
  autoFetch?: boolean
}

export function useInvoice(id: string | undefined, options: UseInvoiceOptions = {}) {
  const { autoFetch = true } = options

  const api = useApi()
  const [invoice, setInvoice] = useState<InvoiceDetailResponse['invoice'] | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchInvoice = useCallback(async () => {
    if (!id) {
      setError('No invoice ID provided')
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await api.get<InvoiceDetailResponse>(`/invoices/${id}`)

      if (response.error) {
        setError(response.error)
        setInvoice(null)
        return
      }

      const data = response.data as InvoiceDetailResponse
      setInvoice(data.invoice || null)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to fetch invoice'
      setError(errorMessage)
      setInvoice(null)
    } finally {
      setLoading(false)
    }
  }, [api, id])

  useEffect(() => {
    if (autoFetch && id) {
      fetchInvoice()
    }
  }, [fetchInvoice, autoFetch, id])

  const refetch = useCallback(() => {
    fetchInvoice()
  }, [fetchInvoice])

  return {
    invoice,
    loading,
    error,
    refetch,
  }
}

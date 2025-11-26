import { useState, useEffect } from 'react'

export interface RevenueMetrics {
  totalRevenue: number
  mtdRevenue: number
  ytdRevenue: number
  averageLoad: number
  trend: number // percentage
}

export interface LoadMetrics {
  totalLoads: number
  activeLoads: number
  completedLoads: number
  averageLoadValue: number
  acceptanceRate: number
}

export interface CarrierMetrics {
  totalCarriers: number
  activeCarriers: number
  approvedCarriers: number
  pendingApprovals: number
  averageRating: number
}

export interface AnalyticsData {
  dateRange: {
    startDate: string
    endDate: string
  }
  revenue: RevenueMetrics
  loads: LoadMetrics
  carriers: CarrierMetrics
  topCarriers: Array<{
    name: string
    revenue: number
    loads: number
    rating: number
  }>
  revenueTrend: Array<{
    date: string
    revenue: number
  }>
  loadDistribution: Array<{
    status: string
    count: number
  }>
}

export interface ReportFilters {
  startDate?: string
  endDate?: string
  carrierId?: string
  userId?: string
  loadType?: string
}

/**
 * Hook for fetching overall analytics data
 */
export function useAnalytics(dateRange?: { startDate: string; endDate: string }) {
  const [data, setData] = useState<AnalyticsData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchAnalytics = async () => {
      try {
        setLoading(true)
        setError(null)

        const queryParams = new URLSearchParams()
        if (dateRange?.startDate) queryParams.append('startDate', dateRange.startDate)
        if (dateRange?.endDate) queryParams.append('endDate', dateRange.endDate)

        const response = await fetch(`/api/analytics?${queryParams}`)

        if (!response.ok) {
          throw new Error('Failed to fetch analytics')
        }

        const analyticsData: AnalyticsData = await response.json()
        setData(analyticsData)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchAnalytics()
  }, [dateRange?.startDate, dateRange?.endDate])

  return { data, loading, error }
}

/**
 * Hook for fetching revenue analytics
 */
export function useRevenueAnalytics(filters?: ReportFilters) {
  const [data, setData] = useState<{
    totalRevenue: number
    mtdRevenue: number
    ytdRevenue: number
    trend: Array<{ date: string; revenue: number; commission: number }>
    byCarrier: Array<{ carrier: string; revenue: number; percentage: number }>
  } | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchRevenueAnalytics = async () => {
      try {
        setLoading(true)
        setError(null)

        const queryParams = new URLSearchParams()
        if (filters?.startDate) queryParams.append('startDate', filters.startDate)
        if (filters?.endDate) queryParams.append('endDate', filters.endDate)
        if (filters?.carrierId) queryParams.append('carrierId', filters.carrierId)

        const response = await fetch(`/api/analytics/revenue?${queryParams}`)

        if (!response.ok) {
          throw new Error('Failed to fetch revenue analytics')
        }

        const revenueData = await response.json()
        setData(revenueData)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchRevenueAnalytics()
  }, [filters])

  return { data, loading, error }
}

/**
 * Hook for fetching load analytics
 */
export function useLoadAnalytics(filters?: ReportFilters) {
  const [data, setData] = useState<{
    totalLoads: number
    activeLoads: number
    completedLoads: number
    cancelledLoads: number
    acceptanceRate: number
    trend: Array<{ date: string; loads: number; completed: number }>
    byStatus: Array<{ status: string; count: number; percentage: number }>
    byType: Array<{ type: string; count: number }>
  } | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchLoadAnalytics = async () => {
      try {
        setLoading(true)
        setError(null)

        const queryParams = new URLSearchParams()
        if (filters?.startDate) queryParams.append('startDate', filters.startDate)
        if (filters?.endDate) queryParams.append('endDate', filters.endDate)
        if (filters?.carrierId) queryParams.append('carrierId', filters.carrierId)

        const response = await fetch(`/api/analytics/loads?${queryParams}`)

        if (!response.ok) {
          throw new Error('Failed to fetch load analytics')
        }

        const loadData = await response.json()
        setData(loadData)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchLoadAnalytics()
  }, [filters])

  return { data, loading, error }
}

/**
 * Hook for fetching carrier analytics and performance
 */
export function useCarrierAnalytics(filters?: ReportFilters) {
  const [data, setData] = useState<{
    totalCarriers: number
    activeCarriers: number
    averageRating: number
    topCarriers: Array<{
      id: string
      name: string
      loads: number
      revenue: number
      rating: number
      acceptanceRate: number
    }>
    ratingDistribution: Array<{ rating: string; count: number }>
    performanceTrend: Array<{ date: string; avgRating: number; activeCarriers: number }>
  } | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchCarrierAnalytics = async () => {
      try {
        setLoading(true)
        setError(null)

        const queryParams = new URLSearchParams()
        if (filters?.startDate) queryParams.append('startDate', filters.startDate)
        if (filters?.endDate) queryParams.append('endDate', filters.endDate)

        const response = await fetch(`/api/analytics/carriers?${queryParams}`)

        if (!response.ok) {
          throw new Error('Failed to fetch carrier analytics')
        }

        const carrierData = await response.json()
        setData(carrierData)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchCarrierAnalytics()
  }, [filters])

  return { data, loading, error }
}

/**
 * Hook for generating and exporting reports
 */
export function useReportGeneration() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const generateReport = async (reportType: string, filters?: ReportFilters, format: 'pdf' | 'excel' = 'pdf') => {
    setLoading(true)
    setError(null)

    try {
      const queryParams = new URLSearchParams({
        type: reportType,
        format: format,
      })

      if (filters?.startDate) queryParams.append('startDate', filters.startDate)
      if (filters?.endDate) queryParams.append('endDate', filters.endDate)
      if (filters?.carrierId) queryParams.append('carrierId', filters.carrierId)

      const response = await fetch(`/api/reports/generate?${queryParams}`)

      if (!response.ok) {
        throw new Error('Failed to generate report')
      }

      const blob = await response.blob()
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `${reportType}-${new Date().toISOString().split('T')[0]}.${format === 'pdf' ? 'pdf' : 'xlsx'}`
      a.click()
      URL.revokeObjectURL(url)

      return blob
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      throw err
    } finally {
      setLoading(false)
    }
  }

  return { generateReport, loading, error }
}

/**
 * Hook for scheduling report generation and email delivery
 */
export function useScheduledReports() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const scheduleReport = async (
    reportType: string,
    frequency: 'daily' | 'weekly' | 'monthly',
    email: string,
    filters?: ReportFilters
  ) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/reports/schedule', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          reportType,
          frequency,
          email,
          filters,
        }),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to schedule report')
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

  return { scheduleReport, loading, error }
}

import { useState, useEffect } from 'react'

export interface AuditLog {
  id: string
  action: string
  actionType: 'create' | 'update' | 'delete' | 'approve' | 'reject' | 'login' | 'logout' | 'download'
  entity: string
  entityId: string
  entityName: string
  user: {
    id: string
    name: string
    email: string
  }
  timestamp: string
  ipAddress: string
  changes?: {
    field: string
    oldValue: any
    newValue: any
  }[]
  status: 'success' | 'failed'
  details?: string
}

export interface AuditLogsResponse {
  data: AuditLog[]
  total: number
  page: number
  pageSize: number
}

/**
 * Hook for fetching audit logs with filtering
 */
export function useAuditLogs(
  page = 1,
  pageSize = 50,
  filters?: {
    actionType?: string
    entity?: string
    userId?: string
    startDate?: string
    endDate?: string
  }
) {
  const [logs, setLogs] = useState<AuditLog[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [total, setTotal] = useState(0)

  useEffect(() => {
    const fetchLogs = async () => {
      try {
        setLoading(true)
        setError(null)

        const queryParams = new URLSearchParams({
          page: page.toString(),
          pageSize: pageSize.toString(),
        })

        if (filters?.actionType) queryParams.append('actionType', filters.actionType)
        if (filters?.entity) queryParams.append('entity', filters.entity)
        if (filters?.userId) queryParams.append('userId', filters.userId)
        if (filters?.startDate) queryParams.append('startDate', filters.startDate)
        if (filters?.endDate) queryParams.append('endDate', filters.endDate)

        const response = await fetch(`/api/admin/audit-logs?${queryParams}`)

        if (!response.ok) {
          throw new Error('Failed to fetch audit logs')
        }

        const data: AuditLogsResponse = await response.json()
        setLogs(data.data)
        setTotal(data.total)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchLogs()
  }, [page, pageSize, filters])

  return { logs, loading, error, total }
}

/**
 * Hook for fetching single audit log details
 */
export function useAuditLog(logId: string | null) {
  const [log, setLog] = useState<AuditLog | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!logId) {
      setLog(null)
      setLoading(false)
      return
    }

    const fetchLog = async () => {
      try {
        setLoading(true)
        setError(null)

        const response = await fetch(`/api/admin/audit-logs/${logId}`)

        if (!response.ok) {
          throw new Error('Failed to fetch audit log')
        }

        const data: AuditLog = await response.json()
        setLog(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchLog()
  }, [logId])

  return { log, loading, error }
}

/**
 * Hook for exporting audit logs
 */
export function useExportAuditLogs() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const exportLogs = async (filters?: { startDate?: string; endDate?: string; format?: 'csv' | 'pdf' }) => {
    setLoading(true)
    setError(null)

    try {
      const queryParams = new URLSearchParams({
        format: filters?.format || 'csv',
      })

      if (filters?.startDate) queryParams.append('startDate', filters.startDate)
      if (filters?.endDate) queryParams.append('endDate', filters.endDate)

      const response = await fetch(`/api/admin/audit-logs/export?${queryParams}`)

      if (!response.ok) {
        throw new Error('Failed to export audit logs')
      }

      const blob = await response.blob()
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `audit-logs-${new Date().toISOString().split('T')[0]}.${filters?.format || 'csv'}`
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

  return { exportLogs, loading, error }
}

/**
 * Hook for searching audit logs
 */
export function useSearchAuditLogs() {
  const [results, setResults] = useState<AuditLog[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const search = async (query: string) => {
    if (!query.trim()) {
      setResults([])
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/admin/audit-logs/search?q=${encodeURIComponent(query)}`)

      if (!response.ok) {
        throw new Error('Search failed')
      }

      const data = await response.json()
      setResults(data.data)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      setResults([])
    } finally {
      setLoading(false)
    }
  }

  return { results, search, loading, error }
}

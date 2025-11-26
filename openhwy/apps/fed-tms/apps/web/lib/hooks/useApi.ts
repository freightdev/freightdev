import { useState, useCallback } from 'react'

interface ApiResponse<T> {
  data?: T
  error?: string
  status?: number
}

interface UseApiOptions {
  baseUrl?: string
  headers?: Record<string, string>
}

export function useApi(options: UseApiOptions = {}) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const baseUrl = options.baseUrl || '/api/v1'

  const request = useCallback(
    async <T,>(
      endpoint: string,
      method: 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' = 'GET',
      body?: unknown,
      customHeaders?: Record<string, string>
    ): Promise<ApiResponse<T>> => {
      setLoading(true)
      setError(null)

      try {
        const url = `${baseUrl}${endpoint}`

        const headers: Record<string, string> = {
          'Content-Type': 'application/json',
          ...options.headers,
          ...customHeaders,
        }

        // Add auth token if available
        const token = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null
        if (token) {
          headers.Authorization = `Bearer ${token}`
        }

        const response = await fetch(url, {
          method,
          headers,
          body: body ? JSON.stringify(body) : undefined,
        })

        const data = await response.json()

        if (!response.ok) {
          const errorMessage = data.error || data.message || 'An error occurred'
          setError(errorMessage)
          return { error: errorMessage, status: response.status }
        }

        setLoading(false)
        return { data: data.data || data, status: response.status }
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Network error'
        setError(errorMessage)
        setLoading(false)
        return { error: errorMessage }
      }
    },
    [baseUrl, options.headers]
  )

  const get = useCallback(
    <T,>(endpoint: string, customHeaders?: Record<string, string>) =>
      request<T>(endpoint, 'GET', undefined, customHeaders),
    [request]
  )

  const post = useCallback(
    <T,>(endpoint: string, body?: unknown, customHeaders?: Record<string, string>) =>
      request<T>(endpoint, 'POST', body, customHeaders),
    [request]
  )

  const put = useCallback(
    <T,>(endpoint: string, body?: unknown, customHeaders?: Record<string, string>) =>
      request<T>(endpoint, 'PUT', body, customHeaders),
    [request]
  )

  const del = useCallback(
    <T,>(endpoint: string, customHeaders?: Record<string, string>) =>
      request<T>(endpoint, 'DELETE', undefined, customHeaders),
    [request]
  )

  const clearError = useCallback(() => setError(null), [])

  return {
    loading,
    error,
    request,
    get,
    post,
    put,
    delete: del,
    clearError,
  }
}

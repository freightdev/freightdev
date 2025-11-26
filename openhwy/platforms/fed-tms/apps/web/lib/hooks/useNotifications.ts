import { useState, useEffect, useCallback } from 'react'

export interface Notification {
  id: string
  type: 'info' | 'success' | 'warning' | 'error' | 'alert'
  title: string
  message: string
  icon?: string
  read: boolean
  timestamp: string
  actionUrl?: string
  actionLabel?: string
  sender?: {
    id: string
    name: string
    avatar?: string
  }
  relatedEntity?: {
    type: 'load' | 'carrier' | 'user' | 'report' | 'payment'
    id: string
    name: string
  }
}

export interface NotificationsResponse {
  notifications: Notification[]
  unreadCount: number
  total: number
  page: number
  pageSize: number
}

export interface NotificationSettings {
  emailNotifications: boolean
  pushNotifications: boolean
  smsNotifications: boolean
  notificationFrequency: 'immediate' | 'hourly' | 'daily' | 'weekly'
  enabledTypes: {
    loads: boolean
    carriers: boolean
    payments: boolean
    system: boolean
    messages: boolean
  }
}

/**
 * Hook for fetching user notifications with pagination
 */
export function useNotifications(page: number = 1, pageSize: number = 20) {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [unreadCount, setUnreadCount] = useState(0)
  const [total, setTotal] = useState(0)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchNotifications = async () => {
      try {
        setLoading(true)
        setError(null)

        const response = await fetch(`/api/notifications?page=${page}&pageSize=${pageSize}`)

        if (!response.ok) {
          throw new Error('Failed to fetch notifications')
        }

        const data: NotificationsResponse = await response.json()
        setNotifications(data.notifications)
        setUnreadCount(data.unreadCount)
        setTotal(data.total)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchNotifications()
  }, [page, pageSize])

  return { notifications, unreadCount, total, loading, error }
}

/**
 * Hook for marking notifications as read
 */
export function useNotificationActions() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const markAsRead = useCallback(async (notificationId: string) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/notifications/${notificationId}/read`, {
        method: 'PATCH',
      })

      if (!response.ok) {
        throw new Error('Failed to mark notification as read')
      }

      return await response.json()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      throw err
    } finally {
      setLoading(false)
    }
  }, [])

  const markAllAsRead = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/notifications/read-all', {
        method: 'PATCH',
      })

      if (!response.ok) {
        throw new Error('Failed to mark all notifications as read')
      }

      return await response.json()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      throw err
    } finally {
      setLoading(false)
    }
  }, [])

  const deleteNotification = useCallback(async (notificationId: string) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/notifications/${notificationId}`, {
        method: 'DELETE',
      })

      if (!response.ok) {
        throw new Error('Failed to delete notification')
      }

      return await response.json()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      throw err
    } finally {
      setLoading(false)
    }
  }, [])

  const deleteAllNotifications = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/notifications/delete-all', {
        method: 'DELETE',
      })

      if (!response.ok) {
        throw new Error('Failed to delete all notifications')
      }

      return await response.json()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unknown error'
      setError(message)
      throw err
    } finally {
      setLoading(false)
    }
  }, [])

  return { markAsRead, markAllAsRead, deleteNotification, deleteAllNotifications, loading, error }
}

/**
 * Hook for managing notification settings and preferences
 */
export function useNotificationPreferences() {
  const [settings, setSettings] = useState<NotificationSettings | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchSettings = async () => {
      try {
        setLoading(true)
        setError(null)

        const response = await fetch('/api/notifications/settings')

        if (!response.ok) {
          throw new Error('Failed to fetch notification settings')
        }

        const data: NotificationSettings = await response.json()
        setSettings(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchSettings()
  }, [])

  const updateSettings = useCallback(
    async (newSettings: Partial<NotificationSettings>) => {
      setLoading(true)
      setError(null)

      try {
        const response = await fetch('/api/notifications/settings', {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(newSettings),
        })

        if (!response.ok) {
          throw new Error('Failed to update settings')
        }

        const data: NotificationSettings = await response.json()
        setSettings(data)
        return data
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Unknown error'
        setError(message)
        throw err
      } finally {
        setLoading(false)
      }
    },
    []
  )

  return { settings, updateSettings, loading, error }
}

/**
 * Hook for searching and filtering notifications
 */
export function useNotificationSearch(query: string = '', type?: string) {
  const [results, setResults] = useState<Notification[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!query && !type) {
      setResults([])
      return
    }

    const searchNotifications = async () => {
      try {
        setLoading(true)
        setError(null)

        const params = new URLSearchParams()
        if (query) params.append('q', query)
        if (type) params.append('type', type)

        const response = await fetch(`/api/notifications/search?${params}`)

        if (!response.ok) {
          throw new Error('Failed to search notifications')
        }

        const data: Notification[] = await response.json()
        setResults(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    const debounceTimer = setTimeout(searchNotifications, 300)
    return () => clearTimeout(debounceTimer)
  }, [query, type])

  return { results, loading, error }
}

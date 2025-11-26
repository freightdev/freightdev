import { useState, useEffect } from 'react'

export interface User {
  id: string
  name: string
  email: string
  role: 'admin' | 'manager' | 'dispatcher' | 'driver' | 'carrier'
  status: 'active' | 'inactive' | 'suspended'
  joinDate: string
  lastLogin: string
  phone?: string
  company?: string
  avatar?: string
}

export interface UserFormData {
  name: string
  email: string
  phone?: string
  company?: string
  role: 'admin' | 'manager' | 'dispatcher' | 'driver' | 'carrier'
  status: 'active' | 'inactive' | 'suspended'
}

export interface UsersResponse {
  data: User[]
  total: number
  page: number
  pageSize: number
}

/**
 * Hook for fetching user list with pagination and filtering
 */
export function useUsers(page = 1, pageSize = 20, filters?: { role?: string; status?: string }) {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [total, setTotal] = useState(0)

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        setLoading(true)
        setError(null)

        const queryParams = new URLSearchParams({
          page: page.toString(),
          pageSize: pageSize.toString(),
        })

        if (filters?.role) queryParams.append('role', filters.role)
        if (filters?.status) queryParams.append('status', filters.status)

        const response = await fetch(`/api/admin/users?${queryParams}`)

        if (!response.ok) {
          throw new Error('Failed to fetch users')
        }

        const data: UsersResponse = await response.json()
        setUsers(data.data)
        setTotal(data.total)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchUsers()
  }, [page, pageSize, filters])

  return { users, loading, error, total }
}

/**
 * Hook for fetching single user details
 */
export function useUser(userId: string | null) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!userId) {
      setUser(null)
      setLoading(false)
      return
    }

    const fetchUser = async () => {
      try {
        setLoading(true)
        setError(null)

        const response = await fetch(`/api/admin/users/${userId}`)

        if (!response.ok) {
          throw new Error('Failed to fetch user')
        }

        const data: User = await response.json()
        setUser(data)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchUser()
  }, [userId])

  return { user, loading, error }
}

/**
 * Hook for managing user creation/update
 */
export function useUserManagement() {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const createUser = async (formData: UserFormData) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/admin/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to create user')
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

  const updateUser = async (userId: string, formData: Partial<UserFormData>) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/admin/users/${userId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to update user')
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

  const deleteUser = async (userId: string) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/admin/users/${userId}`, {
        method: 'DELETE',
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to delete user')
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

  const changeUserStatus = async (userId: string, status: 'active' | 'inactive' | 'suspended') => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/admin/users/${userId}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Failed to update user status')
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

  return { createUser, updateUser, deleteUser, changeUserStatus, loading, error }
}

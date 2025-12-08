'use client'

import React, { useEffect, ReactNode } from 'react'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/contexts/AuthContext'

interface ProtectedRouteProps {
  children: ReactNode
}

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const router = useRouter()
  const { isAuthenticated, loading } = useAuth()

  useEffect(() => {
    if (!loading && !isAuthenticated) {
      router.push('/login')
    }
  }, [isAuthenticated, loading, router])

  if (loading) {
    return (
      <div className="min-h-screen bg-[#0a0a0f] text-[#e0e0e0] flex items-center justify-center">
        <div className="text-center space-y-4">
          <div className="text-5xl">🚀</div>
          <h1 className="text-2xl font-bold">Loading...</h1>
          <p className="text-gray-400">Setting up your dashboard</p>
        </div>
      </div>
    )
  }

  if (!isAuthenticated) {
    return null
  }

  return <>{children}</>
}

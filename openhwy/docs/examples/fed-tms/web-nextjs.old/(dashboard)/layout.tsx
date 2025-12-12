'use client'

import React, { ReactNode, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useAuth } from '@/lib/contexts/AuthContext'
import { useToast } from '@/lib/contexts/ToastContext'
import { ProtectedRoute } from '@/lib/components/ProtectedRoute'
import NotificationBell from '@/components/NotificationBell'

interface DashboardLayoutProps {
  children: ReactNode
}

export default function DashboardLayout({ children }: DashboardLayoutProps) {
  const router = useRouter()
  const { user, logout } = useAuth()
  const { addToast } = useToast()
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [activeNav, setActiveNav] = useState('dashboard')
  const [showLogoutMenu, setShowLogoutMenu] = useState(false)

  const handleLogout = () => {
    logout()
    addToast('Logged out successfully', 'success')
    router.push('/login')
  }

  const navItems = [
    {
      id: 'dashboard',
      label: 'Dashboard',
      icon: '📊',
      href: '/dashboard',
    },
    {
      id: 'drivers',
      label: 'Drivers',
      icon: '👤',
      href: '/dashboard/drivers',
    },
    {
      id: 'loads',
      label: 'Loads',
      icon: '📦',
      href: '/dashboard/loads',
    },
    {
      id: 'tracking',
      label: 'Live Tracking',
      icon: '🗺️',
      href: '/dashboard/tracking',
    },
    {
      id: 'invoicing',
      label: 'Invoicing',
      icon: '💰',
      href: '/dashboard/invoicing',
    },
    {
      id: 'messages',
      label: 'Messages',
      icon: '💬',
      href: '/dashboard/messages',
      badge: 3,
    },
    {
      id: 'documents',
      label: 'Documents',
      icon: '📄',
      href: '/dashboard/documents',
    },
    {
      id: 'forms',
      label: 'Forms & Agreements',
      icon: '📋',
      href: '/dashboard/forms',
    },
    {
      id: 'notifications',
      label: 'Notifications',
      icon: '🔔',
      href: '/dashboard/notifications',
    },
    {
      id: 'admin',
      label: 'Admin Panel',
      icon: '🔧',
      href: '/dashboard/admin',
    },
  ]

  const settingsItems = [
    {
      id: 'profile',
      label: 'Profile',
      icon: '👤',
      href: '/dashboard/profile',
    },
    {
      id: 'account',
      label: 'Account Settings',
      icon: '⚙️',
      href: '/dashboard/settings/account',
    },
    {
      id: 'security',
      label: 'Security',
      icon: '🔒',
      href: '/dashboard/settings/security',
    },
  ]

  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-[#0a0a0f] text-[#e0e0e0] flex">
        {/* SIDEBAR */}
        <aside
        className={`${
          sidebarOpen ? 'w-80' : 'w-0'
        } bg-gradient-to-b from-[#1a1a2e] to-[#16213e] border-r border-white/10 overflow-y-auto transition-all duration-300`}
      >
        {/* Logo */}
        <div className="px-6 py-6 border-b border-white/10">
          <div className="text-2xl font-bold bg-gradient-to-r from-[#d946ef] to-[#a855f7] bg-clip-text text-transparent">
            FED
          </div>
        </div>

        {/* User Profile */}
        {user && (
          <div className="px-5 py-5 flex items-center gap-3 border-b border-white/10">
            <div className="w-10 h-10 rounded-full bg-gradient-to-r from-[#d946ef] to-[#a855f7] flex items-center justify-center font-bold text-white">
              {user.first_name?.[0]}{user.last_name?.[0]}
            </div>
            <div className="flex-1 min-w-0">
              <div className="font-semibold text-sm truncate">
                {user.first_name} {user.last_name}
              </div>
              <div className="text-xs text-gray-400 truncate">Dispatcher</div>
            </div>
          </div>
        )}

        {/* Main Navigation */}
        <nav className="py-4">
          <div className="px-6 pb-4">
            <div className="text-xs font-semibold text-gray-500 uppercase tracking-widest">
              Navigation
            </div>
          </div>

          {navItems.map((item) => (
            <Link
              key={item.id}
              href={item.href}
              onClick={() => setActiveNav(item.id)}
              className={`flex items-center gap-3 px-6 py-3 mx-2 rounded-lg transition-all ${
                activeNav === item.id
                  ? 'bg-[#d946ef]/20 border-l-3 border-[#d946ef]'
                  : 'hover:bg-[#d946ef]/10'
              }`}
            >
              <span className="text-lg w-5">{item.icon}</span>
              <span className="flex-1 text-sm font-medium">{item.label}</span>
              {item.badge && (
                <span className="bg-[#d946ef] text-white text-xs font-bold px-2 py-1 rounded-full">
                  {item.badge}
                </span>
              )}
            </Link>
          ))}

          {/* Settings Section */}
          <div className="px-6 py-4 mt-4 border-t border-white/5">
            <div className="text-xs font-semibold text-gray-500 uppercase tracking-widest mb-4">
              Settings
            </div>

            {settingsItems.map((item) => (
              <Link
                key={item.id}
                href={item.href}
                onClick={() => setActiveNav(item.id)}
                className={`flex items-center gap-3 px-6 py-3 mx-2 rounded-lg transition-all mb-1 ${
                  activeNav === item.id
                    ? 'bg-[#d946ef]/20 border-l-3 border-[#d946ef]'
                    : 'hover:bg-[#d946ef]/10'
                }`}
              >
                <span className="text-lg w-5">{item.icon}</span>
                <span className="text-sm font-medium">{item.label}</span>
              </Link>
            ))}
          </div>
        </nav>

        {/* Logout */}
        <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-white/10 bg-gradient-to-t from-[#0a0a0f]">
          <button
            onClick={handleLogout}
            className="w-full py-2 px-4 rounded-lg bg-red-600/20 hover:bg-red-600/30 text-red-400 text-sm font-semibold transition-colors"
          >
            Logout
          </button>
        </div>
      </aside>

      {/* MAIN CONTENT */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* HEADER */}
        <header className="bg-[#16213e] border-b border-white/10 px-8 py-5 flex justify-between items-center">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="text-2xl hover:text-[#d946ef] transition-colors"
            >
              ☰
            </button>
            <h1 className="text-2xl font-bold">Dispatcher Dashboard</h1>
          </div>

          <div className="flex items-center gap-4">
            <NotificationBell />
            <Link href="/dashboard/settings/account" className="p-2 hover:bg-white/10 rounded-lg transition-colors">
              ⚙️
            </Link>
          </div>
        </header>

        {/* CONTENT */}
        <main className="flex-1 overflow-y-auto bg-[#0a0a0f] p-8">
          {children}
        </main>
      </div>
      </div>
    </ProtectedRoute>
  )
}

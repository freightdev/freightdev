'use client'

import React, { useState, useMemo } from 'react'
import Link from 'next/link'
import { useAnalytics } from '@/lib/hooks/useAnalytics'
import { useNotifications } from '@/lib/hooks/useNotifications'
import { useConversations } from '@/lib/hooks/useMessaging'

export default function DashboardPage() {
  const [dateRange] = useState({
    startDate: new Date(new Date().setDate(new Date().getDate() - 7)).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  })

  const { data: analyticsData, loading: analyticsLoading } = useAnalytics(dateRange)
  const { notifications, unreadCount: unreadNotifications, loading: notificationsLoading } = useNotifications(1, 5)
  const { conversations, unreadTotal: unreadMessages, loading: conversationsLoading } = useConversations(1, 5)

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
    }).format(value)
  }

  const formatPercent = (value: number) => {
    return `${value > 0 ? '+' : ''}${value.toFixed(1)}%`
  }

  const getNotificationTypeColor = (type: string) => {
    switch (type) {
      case 'success':
        return 'bg-green-600/20 text-green-400 border border-green-600/50'
      case 'warning':
        return 'bg-yellow-600/20 text-yellow-400 border border-yellow-600/50'
      case 'error':
        return 'bg-red-600/20 text-red-400 border border-red-600/50'
      case 'alert':
        return 'bg-purple-600/20 text-purple-400 border border-purple-600/50'
      default:
        return 'bg-blue-600/20 text-blue-400 border border-blue-600/50'
    }
  }

  // Build dynamic stats from analytics data
  const stats = useMemo(() => {
    if (!analyticsData) {
      return [
        { icon: '💰', title: 'Total Revenue', value: '$0', change: '+0%', color: 'from-blue-400 to-blue-600' },
        { icon: '📦', title: 'Active Loads', value: '0', change: '+0%', color: 'from-green-400 to-green-600' },
        { icon: '🚚', title: 'Carriers', value: '0', change: '+0%', color: 'from-purple-400 to-purple-600' },
        { icon: '✅', title: 'Acceptance Rate', value: '0%', change: '+0%', color: 'from-orange-400 to-orange-600' },
      ]
    }

    return [
      {
        icon: '💰',
        title: 'Total Revenue',
        value: formatCurrency(analyticsData.revenue?.totalRevenue || 0),
        change: formatPercent(analyticsData.revenue?.monthOverMonthChange || 0),
        color: 'from-blue-400 to-blue-600',
      },
      {
        icon: '📦',
        title: 'Active Loads',
        value: analyticsData.loads?.activeLoads || 0,
        change: formatPercent(analyticsData.loads?.activeLoadsChange || 0),
        color: 'from-green-400 to-green-600',
      },
      {
        icon: '🚚',
        title: 'Active Carriers',
        value: analyticsData.carriers?.activeCarriers || 0,
        change: formatPercent(analyticsData.carriers?.activeCarriersChange || 0),
        color: 'from-purple-400 to-purple-600',
      },
      {
        icon: '✅',
        title: 'Acceptance Rate',
        value: `${(analyticsData.loads?.acceptanceRate || 0).toFixed(1)}%`,
        change: formatPercent(analyticsData.loads?.acceptanceRateChange || 0),
        color: 'from-orange-400 to-orange-600',
      },
    ]
  }, [analyticsData])

  // Get recent loads from analytics
  const recentLoads = useMemo(() => {
    if (!analyticsData?.loads?.recentLoads) {
      return []
    }
    return analyticsData.loads.recentLoads.slice(0, 5)
  }, [analyticsData])

  // Get top carriers from analytics
  const topCarriers = useMemo(() => {
    if (!analyticsData?.topCarriers) {
      return []
    }
    return analyticsData.topCarriers.slice(0, 3)
  }, [analyticsData])

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'In Transit':
      case 'active':
        return 'bg-blue-600/20 text-blue-400 border border-blue-600/50'
      case 'Delivered':
      case 'completed':
        return 'bg-green-600/20 text-green-400 border border-green-600/50'
      case 'Pending':
      case 'pending':
        return 'bg-yellow-600/20 text-yellow-400 border border-yellow-600/50'
      default:
        return 'bg-gray-600/20 text-gray-400 border border-gray-600/50'
    }
  }

  return (
    <div className="space-y-8">
      {/* STATS GRID */}
      <div className="grid grid-cols-4 gap-6">
        {analyticsLoading ? (
          <div className="col-span-4 text-center text-gray-400">Loading metrics...</div>
        ) : (
          stats.map((stat, idx) => (
            <div
              key={idx}
              className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 hover:border-[#d946ef]/50 transition-all hover:shadow-lg hover:shadow-[#d946ef]/20"
            >
              <div className="flex justify-between items-start mb-4">
                <div className={`text-3xl bg-gradient-to-br ${stat.color} bg-clip-text text-transparent`}>
                  {stat.icon}
                </div>
                <div className="text-xs text-green-400 font-semibold">
                  {stat.change}
                </div>
              </div>

              <h3 className="text-gray-400 text-sm font-medium mb-2">{stat.title}</h3>
              <p className="text-3xl font-bold">{stat.value}</p>
            </div>
          ))
        )}
      </div>

      {/* ALERTS AND NOTIFICATIONS GRID */}
      <div className="grid grid-cols-2 gap-6">
        {/* RECENT NOTIFICATIONS */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-bold">Recent Notifications</h2>
            <Link
              href="/dashboard/notifications"
              className="text-sm text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
            >
              View All {unreadNotifications > 0 && `(${unreadNotifications})`} →
            </Link>
          </div>

          {notificationsLoading ? (
            <p className="text-gray-400 text-sm">Loading notifications...</p>
          ) : notifications && notifications.length > 0 ? (
            <div className="space-y-3">
              {notifications.slice(0, 5).map((notification) => (
                <div
                  key={notification.id}
                  className={`p-3 rounded-lg border ${getNotificationTypeColor(notification.type)}`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-sm">{notification.title}</p>
                      <p className="text-xs text-gray-400 mt-1 truncate">{notification.message}</p>
                    </div>
                    {!notification.read && <span className="flex-shrink-0 w-2 h-2 bg-blue-500 rounded-full mt-1" />}
                  </div>
                  <p className="text-xs text-gray-500 mt-2">
                    {new Date(notification.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </p>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-400 text-sm">No notifications yet</p>
          )}
        </div>

        {/* RECENT MESSAGES */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-bold">Recent Messages</h2>
            <Link
              href="/dashboard/messages"
              className="text-sm text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
            >
              View All {unreadMessages > 0 && `(${unreadMessages})`} →
            </Link>
          </div>

          {conversationsLoading ? (
            <p className="text-gray-400 text-sm">Loading conversations...</p>
          ) : conversations && conversations.length > 0 ? (
            <div className="space-y-3">
              {conversations.slice(0, 5).map((conversation) => (
                <Link
                  key={conversation.id}
                  href={`/dashboard/messages?id=${conversation.id}`}
                  className="p-3 rounded-lg border border-white/10 hover:border-blue-500/50 transition-colors block"
                >
                  <div className="flex items-start gap-3">
                    <div className="relative flex-shrink-0 w-8 h-8 bg-gradient-to-br from-purple-500 to-blue-500 rounded-full flex items-center justify-center">
                      <span className="text-xs font-bold text-white">
                        {conversation.name
                          .split(' ')
                          .map((n: string) => n[0])
                          .join('')
                          .substring(0, 2)
                          .toUpperCase()}
                      </span>
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="font-semibold text-sm">{conversation.name}</p>
                      <p className="text-xs text-gray-400 truncate">
                        {conversation.lastMessage?.content || 'No messages yet'}
                      </p>
                    </div>
                    {conversation.unreadCount > 0 && (
                      <span className="flex-shrink-0 bg-blue-500 text-white text-xs font-bold px-2 py-1 rounded-full">
                        {conversation.unreadCount}
                      </span>
                    )}
                  </div>
                </Link>
              ))}
            </div>
          ) : (
            <p className="text-gray-400 text-sm">No conversations yet</p>
          )}
        </div>
      </div>

      {/* RECENT LOADS */}
      {recentLoads && recentLoads.length > 0 && (
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-bold">Recent Loads</h2>
            <Link
              href="/dashboard/loads"
              className="text-sm text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
            >
              View All →
            </Link>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/10">
                  <th className="text-left py-3 px-4 text-xs font-semibold text-gray-400 uppercase">
                    Load ID
                  </th>
                  <th className="text-left py-3 px-4 text-xs font-semibold text-gray-400 uppercase">
                    Driver
                  </th>
                  <th className="text-left py-3 px-4 text-xs font-semibold text-gray-400 uppercase">
                    Route
                  </th>
                  <th className="text-left py-3 px-4 text-xs font-semibold text-gray-400 uppercase">
                    Status
                  </th>
                  <th className="text-left py-3 px-4 text-xs font-semibold text-gray-400 uppercase">
                    ETA
                  </th>
                  <th className="text-left py-3 px-4 text-xs font-semibold text-gray-400 uppercase">
                    Progress
                  </th>
                </tr>
              </thead>
              <tbody>
                {recentLoads.map((load) => (
                  <tr
                    key={load.id}
                    className="border-b border-white/5 hover:bg-white/5 transition-colors"
                  >
                    <td className="py-4 px-4">
                      <Link
                        href={`/dashboard/loads/${load.id}`}
                        className="font-semibold text-[#d946ef] hover:text-[#d946ef]/80"
                      >
                        {load.id}
                      </Link>
                    </td>
                    <td className="py-4 px-4 text-sm">{load.driver || 'Unassigned'}</td>
                    <td className="py-4 px-4 text-sm text-gray-400">
                      {load.from} → {load.to}
                    </td>
                    <td className="py-4 px-4">
                      <span
                        className={`text-xs font-semibold px-3 py-1 rounded-full ${getStatusColor(
                          load.status
                        )}`}
                      >
                        {load.status}
                      </span>
                    </td>
                    <td className="py-4 px-4 text-sm text-gray-400">{load.eta || 'Pending'}</td>
                    <td className="py-4 px-4">
                      <div className="w-32 bg-white/10 rounded-full h-2 overflow-hidden">
                        <div
                          className="bg-gradient-to-r from-[#d946ef] to-[#a855f7] h-full"
                          style={{ width: `${load.progress || 0}%` }}
                        ></div>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* TOP CARRIERS */}
      {topCarriers && topCarriers.length > 0 && (
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-xl font-bold">Top Performing Carriers</h2>
            <Link
              href="/dashboard/admin/carriers"
              className="text-sm text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
            >
              View All →
            </Link>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {topCarriers.map((carrier) => (
              <div
                key={carrier.id}
                className="bg-white/5 border border-white/10 rounded-lg p-4 hover:border-[#d946ef]/50 transition-all"
              >
                <h3 className="font-semibold text-white mb-3">{carrier.name}</h3>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-400">Revenue:</span>
                    <span className="text-white font-semibold">{formatCurrency(carrier.revenue || 0)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Loads:</span>
                    <span className="text-white font-semibold">{carrier.loads || 0}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-400">Rating:</span>
                    <span className="text-yellow-400 font-semibold">
                      {(carrier.rating || 0).toFixed(1)} ⭐
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* QUICK ACTIONS */}
      <div className="grid grid-cols-3 gap-6">
        <Link
          href="/dashboard/loads/new"
          className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 hover:border-[#d946ef]/50 transition-all hover:shadow-lg hover:shadow-[#d946ef]/20 text-center group"
        >
          <div className="text-4xl mb-3 group-hover:scale-110 transition-transform">
            ➕
          </div>
          <h3 className="font-bold mb-2">Create Load</h3>
          <p className="text-xs text-gray-400">
            Start a new load assignment
          </p>
        </Link>

        <Link
          href="/dashboard/drivers"
          className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 hover:border-[#d946ef]/50 transition-all hover:shadow-lg hover:shadow-[#d946ef]/20 text-center group"
        >
          <div className="text-4xl mb-3 group-hover:scale-110 transition-transform">
            👥
          </div>
          <h3 className="font-bold mb-2">Manage Drivers</h3>
          <p className="text-xs text-gray-400">
            View and manage your fleet
          </p>
        </Link>

        <Link
          href="/dashboard/invoicing"
          className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 hover:border-[#d946ef]/50 transition-all hover:shadow-lg hover:shadow-[#d946ef]/20 text-center group"
        >
          <div className="text-4xl mb-3 group-hover:scale-110 transition-transform">
            💳
          </div>
          <h3 className="font-bold mb-2">View Invoices</h3>
          <p className="text-xs text-gray-400">
            Check billing and payments
          </p>
        </Link>
      </div>
    </div>
  )
}

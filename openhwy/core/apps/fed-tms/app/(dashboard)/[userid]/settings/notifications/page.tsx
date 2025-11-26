'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useNotifications, useNotificationActions } from '@/lib/hooks/useNotifications'

export default function NotificationsPage() {
  const [currentPage, setCurrentPage] = useState(1)
  const [filterType, setFilterType] = useState<string | null>(null)
  const [searchQuery, setSearchQuery] = useState('')

  const { notifications, unreadCount, total, loading, error } = useNotifications(currentPage)
  const { markAsRead, markAllAsRead, deleteNotification, deleteAllNotifications } =
    useNotificationActions()

  const pageSize = 20
  const totalPages = Math.ceil(total / pageSize)

  const filteredNotifications =
    filterType && filterType !== 'all'
      ? notifications.filter((n) => n.type === filterType)
      : notifications

  const searchedNotifications = searchQuery
    ? filteredNotifications.filter(
        (n) =>
          n.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
          n.message.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : filteredNotifications

  const getNotificationIcon = (type: string) => {
    switch (type) {
      case 'info':
        return 'ℹ️'
      case 'success':
        return '✅'
      case 'warning':
        return '⚠️'
      case 'error':
        return '❌'
      case 'alert':
        return '🔔'
      default:
        return '📬'
    }
  }

  const getNotificationColor = (type: string) => {
    switch (type) {
      case 'info':
        return 'border-blue-500/30 bg-blue-500/10'
      case 'success':
        return 'border-green-500/30 bg-green-500/10'
      case 'warning':
        return 'border-yellow-500/30 bg-yellow-500/10'
      case 'error':
        return 'border-red-500/30 bg-red-500/10'
      case 'alert':
        return 'border-purple-500/30 bg-purple-500/10'
      default:
        return 'border-white/10 bg-white/5'
    }
  }

  const handleMarkAsRead = async (notificationId: string) => {
    try {
      await markAsRead(notificationId)
      // Notification will be refreshed on next fetch
    } catch (err) {
      console.error('Failed to mark as read:', err)
    }
  }

  const handleDelete = async (notificationId: string) => {
    try {
      await deleteNotification(notificationId)
      // Notification will be removed on next fetch
    } catch (err) {
      console.error('Failed to delete notification:', err)
    }
  }

  const handleMarkAllAsRead = async () => {
    try {
      await markAllAsRead()
    } catch (err) {
      console.error('Failed to mark all as read:', err)
    }
  }

  const handleDeleteAll = async () => {
    if (confirm('Are you sure you want to delete all notifications?')) {
      try {
        await deleteAllNotifications()
      } catch (err) {
        console.error('Failed to delete all notifications:', err)
      }
    }
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Notifications</h1>
          <p className="text-gray-400 mt-2">
            {unreadCount} unread of {total} total notifications
          </p>
        </div>
        {unreadCount > 0 && (
          <div className="flex gap-2">
            <button
              onClick={handleMarkAllAsRead}
              className="px-4 py-2 bg-blue-500/20 border border-blue-500/30 rounded-lg text-blue-400 hover:bg-blue-500/30 transition-colors text-sm font-semibold"
            >
              Mark All as Read
            </button>
            <button
              onClick={handleDeleteAll}
              className="px-4 py-2 bg-red-500/20 border border-red-500/30 rounded-lg text-red-400 hover:bg-red-500/30 transition-colors text-sm font-semibold"
            >
              Clear All
            </button>
          </div>
        )}
      </div>

      {/* SEARCH AND FILTERS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-lg font-bold">Search & Filter</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-2">Search Notifications</label>
            <input
              type="text"
              placeholder="Search by title or message..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value)
                setCurrentPage(1)
              }}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white placeholder-gray-500 focus:outline-none focus:border-blue-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Filter by Type</label>
            <select
              value={filterType || 'all'}
              onChange={(e) => {
                setFilterType(e.target.value === 'all' ? null : e.target.value)
                setCurrentPage(1)
              }}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-blue-500/50 transition-colors"
            >
              <option value="all">All Types</option>
              <option value="info">Info</option>
              <option value="success">Success</option>
              <option value="warning">Warning</option>
              <option value="error">Error</option>
              <option value="alert">Alert</option>
            </select>
          </div>
        </div>
      </div>

      {/* LOADING STATE */}
      {loading && (
        <div className="text-center py-12">
          <p className="text-gray-400">Loading notifications...</p>
        </div>
      )}

      {/* ERROR STATE */}
      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6">
          <p className="text-red-400">Error loading notifications: {error}</p>
        </div>
      )}

      {/* EMPTY STATE */}
      {!loading && !error && searchedNotifications.length === 0 && (
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-12 text-center">
          <p className="text-4xl mb-4">📭</p>
          <h3 className="text-xl font-bold mb-2">No Notifications</h3>
          <p className="text-gray-400">
            {searchQuery
              ? 'No notifications match your search'
              : filterType
                ? `No ${filterType} notifications`
                : 'You are all caught up!'}
          </p>
        </div>
      )}

      {/* NOTIFICATIONS LIST */}
      {!loading && !error && searchedNotifications.length > 0 && (
        <div className="space-y-3">
          {searchedNotifications.map((notification) => (
            <div
              key={notification.id}
              className={`${getNotificationColor(notification.type)} rounded-lg border p-4 hover:shadow-lg transition-all ${
                !notification.read ? 'ring-2 ring-blue-500/50' : ''
              }`}
            >
              <div className="flex items-start gap-4">
                {/* Icon */}
                <div className="text-2xl flex-shrink-0">{getNotificationIcon(notification.type)}</div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1">
                      <h3 className="font-semibold text-white">{notification.title}</h3>
                      <p className="text-sm text-gray-300 mt-1">{notification.message}</p>

                      {notification.relatedEntity && (
                        <p className="text-xs text-gray-400 mt-2">
                          Related to:{' '}
                          <span className="font-semibold">
                            {notification.relatedEntity.type} - {notification.relatedEntity.name}
                          </span>
                        </p>
                      )}

                      <div className="flex items-center gap-3 mt-3">
                        <span className="text-xs text-gray-400">
                          {new Date(notification.timestamp).toLocaleDateString()} at{' '}
                          {new Date(notification.timestamp).toLocaleTimeString([], {
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </span>
                        {!notification.read && (
                          <span className="px-2 py-1 bg-blue-500/20 border border-blue-500/30 rounded-full text-blue-400 text-xs font-semibold">
                            Unread
                          </span>
                        )}
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex gap-2 flex-shrink-0">
                      {notification.actionUrl && (
                        <Link
                          href={notification.actionUrl}
                          className="px-3 py-1 bg-white/10 border border-white/20 rounded text-white hover:bg-white/20 transition-colors text-xs font-semibold whitespace-nowrap"
                        >
                          {notification.actionLabel || 'View'}
                        </Link>
                      )}
                      {!notification.read && (
                        <button
                          onClick={() => handleMarkAsRead(notification.id)}
                          className="px-3 py-1 bg-blue-500/20 border border-blue-500/30 rounded text-blue-400 hover:bg-blue-500/30 transition-colors text-xs font-semibold"
                        >
                          Mark Read
                        </button>
                      )}
                      <button
                        onClick={() => handleDelete(notification.id)}
                        className="px-3 py-1 bg-red-500/20 border border-red-500/30 rounded text-red-400 hover:bg-red-500/30 transition-colors text-xs font-semibold"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* PAGINATION */}
      {!loading && !error && totalPages > 1 && (
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
          <div className="flex items-center justify-between">
            <p className="text-sm text-gray-400">
              Page {currentPage} of {totalPages}
            </p>
            <div className="flex gap-2">
              <button
                disabled={currentPage === 1}
                onClick={() => setCurrentPage(currentPage - 1)}
                className="px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white hover:bg-white/20 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                ← Previous
              </button>
              <button
                disabled={currentPage === totalPages}
                onClick={() => setCurrentPage(currentPage + 1)}
                className="px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white hover:bg-white/20 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Next →
              </button>
            </div>
          </div>
        </div>
      )}

      {/* INFO CARD */}
      <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
        <p className="text-sm text-blue-400">
          <strong>💡 Tip:</strong> You can manage notification preferences in{' '}
          <Link
            href="/dashboard/notifications/preferences"
            className="underline hover:text-blue-300 transition-colors"
          >
            notification settings
          </Link>
          . Control how and when you receive notifications from different systems.
        </p>
      </div>
    </div>
  )
}

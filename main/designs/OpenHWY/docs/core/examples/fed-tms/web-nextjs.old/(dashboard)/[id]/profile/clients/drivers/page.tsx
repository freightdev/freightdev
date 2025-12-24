'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useDrivers } from '@/lib/hooks'
import { useToast } from '@/lib/contexts/ToastContext'

export default function DriversPage() {
  const [searchTerm, setSearchTerm] = useState('')
  const [filterStatus, setFilterStatus] = useState('all')
  const { drivers, loading, error, refetch } = useDrivers({
    search: searchTerm,
    status: filterStatus,
    autoFetch: true,
  })
  const { addToast } = useToast()

  React.useEffect(() => {
    if (error) {
      addToast(error, 'error')
    }
  }, [error, addToast])

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-600/20 text-green-400 border border-green-600/50'
      case 'inactive':
        return 'bg-gray-600/20 text-gray-400 border border-gray-600/50'
      case 'on_leave':
        return 'bg-yellow-600/20 text-yellow-400 border border-yellow-600/50'
      case 'suspended':
        return 'bg-red-600/20 text-red-400 border border-red-600/50'
      default:
        return 'bg-gray-600/20 text-gray-400 border border-gray-600/50'
    }
  }

  const getRatingColor = (rating: number) => {
    if (rating >= 4.7) return 'text-green-400'
    if (rating >= 4.0) return 'text-blue-400'
    return 'text-yellow-400'
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Drivers</h1>
        <Link
          href="/dashboard/drivers/new"
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          + Add Driver
        </Link>
      </div>

      {/* FILTERS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 flex gap-4">
        <div className="flex-1">
          <input
            type="text"
            placeholder="Search by name, license, or email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>
        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          className="bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors cursor-pointer"
        >
          <option value="all">All Statuses</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
          <option value="on_leave">On Leave</option>
          <option value="suspended">Suspended</option>
        </select>
      </div>

      {/* LOADING STATE */}
      {loading && (
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-12 text-center">
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="w-8 h-8 border-4 border-[#d946ef]/20 border-t-[#d946ef] rounded-full animate-spin"></div>
            <p className="text-gray-400">Loading drivers...</p>
          </div>
        </div>
      )}

      {/* ERROR STATE */}
      {error && !loading && (
        <div className="bg-red-600/20 border border-red-600/50 rounded-xl p-6 text-center">
          <p className="text-red-400 mb-4">{error}</p>
          <button
            onClick={refetch}
            className="px-4 py-2 rounded-lg bg-red-600/20 border border-red-600/50 text-red-400 font-semibold hover:bg-red-600/30 transition-colors"
          >
            Try Again
          </button>
        </div>
      )}

      {/* DRIVERS GRID */}
      {!loading && !error && (
        <>
          <div className="grid grid-cols-2 gap-6">
            {drivers.map((driver) => (
              <Link
                key={driver.id}
                href={`/dashboard/drivers/${driver.id}`}
                className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 hover:border-[#d946ef]/50 transition-all hover:shadow-lg hover:shadow-[#d946ef]/20 group"
              >
                {/* Header */}
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-lg font-bold group-hover:text-[#d946ef] transition-colors">
                      {driver.name || `${driver.first_name} ${driver.last_name}`}
                    </h3>
                    <p className="text-sm text-gray-400">{driver.license}</p>
                  </div>
                  <span
                    className={`text-xs font-semibold px-3 py-1 rounded-full ${getStatusColor(
                      driver.status
                    )}`}
                  >
                    {driver.status}
                  </span>
                </div>

                {/* Contact Info */}
                <div className="space-y-2 mb-4 text-sm text-gray-400">
                  <p>📞 {driver.phone || 'N/A'}</p>
                  <p>✉️ {driver.email || 'N/A'}</p>
                </div>

                {/* Vehicle Info */}
                <div className="bg-white/5 rounded-lg p-3 mb-4">
                  <p className="text-xs text-gray-500 mb-1">Vehicle</p>
                  <p className="text-sm font-semibold">{driver.vehicle || 'Not assigned'}</p>
                  <p className="text-xs text-gray-400 mt-1">Plate: {driver.license_plate || 'N/A'}</p>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-2 gap-4">
                  <div className="bg-white/5 rounded-lg p-3">
                    <p className="text-xs text-gray-500 mb-1">Rating</p>
                    <p className={`text-xl font-bold ${getRatingColor(driver.rating)}`}>
                      {driver.rating ? `${driver.rating}⭐` : 'N/A'}
                    </p>
                  </div>
                  <div className="bg-white/5 rounded-lg p-3">
                    <p className="text-xs text-gray-500 mb-1">Completed Loads</p>
                    <p className="text-xl font-bold text-blue-400">{driver.completed_loads || 0}</p>
                  </div>
                </div>
              </Link>
            ))}
          </div>

          {drivers.length === 0 && (
            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-12 text-center">
              <p className="text-gray-400">No drivers found matching your criteria</p>
            </div>
          )}
        </>
      )}
    </div>
  )
}

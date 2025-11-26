'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useLoads } from '@/lib/hooks'
import { useToast } from '@/lib/contexts/ToastContext'

export default function LoadsPage() {
  const [searchTerm, setSearchTerm] = useState('')
  const [filterStatus, setFilterStatus] = useState('all')
  const { loads, loading, error, refetch } = useLoads({
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
      case 'in_transit':
        return 'bg-blue-600/20 text-blue-400 border border-blue-600/50'
      case 'delivered':
        return 'bg-green-600/20 text-green-400 border border-green-600/50'
      case 'pending':
        return 'bg-yellow-600/20 text-yellow-400 border border-yellow-600/50'
      case 'cancelled':
        return 'bg-red-600/20 text-red-400 border border-red-600/50'
      default:
        return 'bg-gray-600/20 text-gray-400 border border-gray-600/50'
    }
  }

  const getProgressColor = (status: string) => {
    switch (status) {
      case 'in_transit':
        return 'from-blue-500 to-blue-400'
      case 'delivered':
        return 'from-green-500 to-green-400'
      case 'pending':
        return 'from-yellow-500 to-yellow-400'
      case 'cancelled':
        return 'from-red-500 to-red-400'
      default:
        return 'from-[#d946ef] to-[#a855f7]'
    }
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Loads</h1>
        <Link
          href="/dashboard/loads/new"
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          + Create Load
        </Link>
      </div>

      {/* FILTERS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 flex gap-4">
        <div className="flex-1">
          <input
            type="text"
            placeholder="Search by reference, origin, or destination..."
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
          <option value="in_transit">In Transit</option>
          <option value="pending">Pending</option>
          <option value="delivered">Delivered</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </div>

      {/* LOADING STATE */}
      {loading && (
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-12 text-center">
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="w-8 h-8 border-4 border-[#d946ef]/20 border-t-[#d946ef] rounded-full animate-spin"></div>
            <p className="text-gray-400">Loading loads...</p>
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

      {/* LOADS TABLE */}
      {!loading && !error && (
        <>
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-white/10">
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Load ID
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Driver
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Route
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Distance
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Rate
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Status
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      ETA
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Progress
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {loads.map((load) => (
                    <tr
                      key={load.id}
                      className="border-b border-white/5 hover:bg-white/5 transition-colors"
                    >
                      <td className="py-4 px-4">
                        <Link
                          href={`/dashboard/loads/${load.id}`}
                          className="font-semibold text-[#d946ef] hover:text-[#d946ef]/80"
                        >
                          {load.reference}
                        </Link>
                      </td>
                      <td className="py-4 px-4 text-sm">{load.driver_name || 'Unassigned'}</td>
                      <td className="py-4 px-4 text-sm text-gray-400">
                        {load.origin} → {load.destination}
                      </td>
                      <td className="py-4 px-4 text-sm text-gray-400">
                        {load.distance ? `${load.distance} miles` : 'N/A'}
                      </td>
                      <td className="py-4 px-4 text-sm font-semibold">${load.rate}</td>
                      <td className="py-4 px-4">
                        <span className={`text-xs font-semibold px-3 py-1 rounded-full ${getStatusColor(load.status)}`}>
                          {load.status.replace('_', ' ')}
                        </span>
                      </td>
                      <td className="py-4 px-4 text-sm text-gray-400">{load.eta || 'TBD'}</td>
                      <td className="py-4 px-4">
                        <div className="w-32 bg-white/10 rounded-full h-2 overflow-hidden">
                          <div
                            className={`bg-gradient-to-r ${getProgressColor(load.status)} h-full`}
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

          {loads.length === 0 && (
            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-12 text-center">
              <p className="text-gray-400">No loads found matching your criteria</p>
            </div>
          )}
        </>
      )}
    </div>
  )
}

'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useLoadAnalytics } from '@/lib/hooks/useAnalytics'

export default function LoadReportPage() {
  const [dateRange, setDateRange] = useState({
    startDate: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  })

  const [selectedCarrier, setSelectedCarrier] = useState<string | null>(null)
  const [selectedStatus, setSelectedStatus] = useState<string | null>(null)

  const { data, loading, error } = useLoadAnalytics({
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    carrierId: selectedCarrier || undefined,
    loadType: selectedStatus || undefined,
  })

  const handleDateChange = (field: 'startDate' | 'endDate', value: string) => {
    setDateRange((prev) => ({ ...prev, [field]: value }))
  }

  const handleExportPDF = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=loads&format=pdf&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `loads-report-${dateRange.startDate}-to-${dateRange.endDate}.pdf`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export PDF:', err)
    }
  }

  const handleExportExcel = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=loads&format=excel&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `loads-report-${dateRange.startDate}-to-${dateRange.endDate}.xlsx`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export Excel:', err)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'text-green-400'
      case 'in transit':
        return 'text-blue-400'
      case 'pending':
        return 'text-yellow-400'
      case 'cancelled':
        return 'text-red-400'
      default:
        return 'text-gray-400'
    }
  }

  const getStatusBgColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'delivered':
        return 'bg-green-500/20 border border-green-500/30'
      case 'in transit':
        return 'bg-blue-500/20 border border-blue-500/30'
      case 'pending':
        return 'bg-yellow-500/20 border border-yellow-500/30'
      case 'cancelled':
        return 'bg-red-500/20 border border-red-500/30'
      default:
        return 'bg-white/5 border border-white/10'
    }
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <Link href="/dashboard/reports" className="text-gray-400 hover:text-white transition-colors">
              Reports
            </Link>
            <span className="text-gray-600">/</span>
            <span className="text-white">Load Report</span>
          </div>
          <h1 className="text-3xl font-bold">Load Report</h1>
          <p className="text-gray-400 mt-2">Load volume, distribution, and delivery performance metrics</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={handleExportPDF}
            className="px-4 py-2 bg-red-500/20 border border-red-500/30 rounded-lg text-red-400 hover:bg-red-500/30 transition-colors text-sm font-semibold"
          >
            📄 Export PDF
          </button>
          <button
            onClick={handleExportExcel}
            className="px-4 py-2 bg-green-500/20 border border-green-500/30 rounded-lg text-green-400 hover:bg-green-500/30 transition-colors text-sm font-semibold"
          >
            📊 Export Excel
          </button>
        </div>
      </div>

      {/* DATE RANGE AND FILTERS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-lg font-bold">Filters</h2>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium mb-2">Start Date</label>
            <input
              type="date"
              value={dateRange.startDate}
              onChange={(e) => handleDateChange('startDate', e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-blue-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">End Date</label>
            <input
              type="date"
              value={dateRange.endDate}
              onChange={(e) => handleDateChange('endDate', e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-blue-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Status</label>
            <select
              value={selectedStatus || ''}
              onChange={(e) => setSelectedStatus(e.target.value || null)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-blue-500/50 transition-colors"
            >
              <option value="">All Status</option>
              <option value="delivered">Delivered</option>
              <option value="in_transit">In Transit</option>
              <option value="pending">Pending</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
          <div className="flex items-end">
            <button
              onClick={() =>
                setDateRange({
                  startDate: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
                  endDate: new Date().toISOString().split('T')[0],
                })
              }
              className="w-full px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white hover:bg-white/20 transition-colors"
            >
              Last 30 Days
            </button>
          </div>
        </div>
      </div>

      {/* LOADING STATE */}
      {loading && (
        <div className="text-center py-12">
          <p className="text-gray-400">Loading load data...</p>
        </div>
      )}

      {/* ERROR STATE */}
      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6">
          <p className="text-red-400">Error loading load data: {error}</p>
        </div>
      )}

      {/* LOAD DATA */}
      {data && !loading && !error && (
        <>
          {/* LOAD SUMMARY CARDS */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-xl border border-blue-500/30 p-6 space-y-3">
              <p className="text-sm text-gray-400">Total Loads</p>
              <p className="text-4xl font-bold">{data.totalLoads}</p>
              <p className="text-sm text-blue-400">Period total</p>
            </div>

            <div className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 rounded-xl border border-purple-500/30 p-6 space-y-3">
              <p className="text-sm text-gray-400">Active Loads</p>
              <p className="text-4xl font-bold">{data.activeLoads}</p>
              <p className="text-sm text-purple-400">Currently in transit</p>
            </div>

            <div className="bg-gradient-to-br from-green-500/20 to-green-600/20 rounded-xl border border-green-500/30 p-6 space-y-3">
              <p className="text-sm text-gray-400">Completed Loads</p>
              <p className="text-4xl font-bold">{data.completedLoads}</p>
              <p className="text-sm text-green-400">Successfully delivered</p>
            </div>

            <div className="bg-gradient-to-br from-amber-500/20 to-amber-600/20 rounded-xl border border-amber-500/30 p-6 space-y-3">
              <p className="text-sm text-gray-400">Acceptance Rate</p>
              <p className="text-4xl font-bold">{(data.acceptanceRate * 100).toFixed(1)}%</p>
              <p className="text-sm text-amber-400">Carrier acceptance</p>
            </div>
          </div>

          {/* LOAD TREND SECTION */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h2 className="text-xl font-bold">Load Trend</h2>

            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-white/10">
                    <th className="px-4 py-3 text-left font-semibold text-gray-400">Date</th>
                    <th className="px-4 py-3 text-right font-semibold text-gray-400">Total Loads</th>
                    <th className="px-4 py-3 text-right font-semibold text-gray-400">Completed</th>
                    <th className="px-4 py-3 text-right font-semibold text-gray-400">Completion Rate</th>
                  </tr>
                </thead>
                <tbody>
                  {data.trend.map((item, index) => {
                    const completionRate = item.loads > 0 ? (item.completed / item.loads) * 100 : 0
                    return (
                      <tr key={index} className="border-b border-white/5 hover:bg-white/5 transition-colors">
                        <td className="px-4 py-3 text-white">{new Date(item.date).toLocaleDateString()}</td>
                        <td className="px-4 py-3 text-right font-semibold text-blue-400">{item.loads}</td>
                        <td className="px-4 py-3 text-right font-semibold text-green-400">{item.completed}</td>
                        <td className="px-4 py-3 text-right font-semibold text-amber-400">{completionRate.toFixed(1)}%</td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </div>

          {/* LOAD STATUS DISTRIBUTION */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h2 className="text-xl font-bold">Load Distribution by Status</h2>

            <div className="space-y-3">
              {data.byStatus.map((item, index) => {
                const percentage = data.totalLoads > 0 ? (item.count / data.totalLoads) * 100 : 0
                return (
                  <div key={index} className={`${getStatusBgColor(item.status)} rounded-lg p-4 transition-colors`}>
                    <div className="flex items-center justify-between mb-3">
                      <div>
                        <p className="font-semibold text-white capitalize">{item.status}</p>
                        <p className={`text-sm ${getStatusColor(item.status)}`}>{item.count} loads</p>
                      </div>
                      <p className={`text-2xl font-bold ${getStatusColor(item.status)}`}>{percentage.toFixed(1)}%</p>
                    </div>
                    <div className="w-full bg-white/10 rounded-full h-2 overflow-hidden">
                      <div
                        className={`h-full transition-all ${
                          item.status.toLowerCase() === 'delivered'
                            ? 'bg-gradient-to-r from-green-500 to-green-600'
                            : item.status.toLowerCase() === 'in transit'
                              ? 'bg-gradient-to-r from-blue-500 to-blue-600'
                              : item.status.toLowerCase() === 'pending'
                                ? 'bg-gradient-to-r from-yellow-500 to-yellow-600'
                                : 'bg-gradient-to-r from-red-500 to-red-600'
                        }`}
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                  </div>
                )
              })}
            </div>
          </div>

          {/* LOAD TYPE BREAKDOWN */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h2 className="text-xl font-bold">Load Distribution by Type</h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {data.byType.map((item, index) => {
                const percentage = data.totalLoads > 0 ? (item.count / data.totalLoads) * 100 : 0
                return (
                  <div key={index} className="bg-white/5 border border-white/10 rounded-lg p-4 hover:border-white/20 transition-colors">
                    <p className="text-sm text-gray-400 uppercase tracking-wide capitalize">{item.type}</p>
                    <p className="text-3xl font-bold mt-2">{item.count}</p>
                    <div className="mt-3 w-full bg-white/10 rounded-full h-1 overflow-hidden">
                      <div
                        className="bg-gradient-to-r from-blue-500 to-blue-600 h-full"
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                    <p className="text-xs text-gray-500 mt-2">{percentage.toFixed(1)}% of total</p>
                  </div>
                )
              })}
            </div>
          </div>

          {/* SUMMARY STATS */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <div>
              <p className="text-xs text-gray-400 uppercase tracking-wide">Cancelled Loads</p>
              <p className="text-2xl font-bold mt-1 text-red-400">{data.cancelledLoads}</p>
            </div>
            <div>
              <p className="text-xs text-gray-400 uppercase tracking-wide">Avg Loads/Day</p>
              <p className="text-2xl font-bold mt-1">
                {(data.totalLoads / (data.trend.length || 1)).toFixed(1)}
              </p>
            </div>
            <div>
              <p className="text-xs text-gray-400 uppercase tracking-wide">On-Time Rate</p>
              <p className="text-2xl font-bold mt-1 text-green-400">98.5%</p>
            </div>
            <div>
              <p className="text-xs text-gray-400 uppercase tracking-wide">Report Generated</p>
              <p className="text-2xl font-bold mt-1">{new Date().toLocaleDateString()}</p>
            </div>
          </div>

          {/* INFO CARDS */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
              <p className="text-sm text-blue-400">
                <strong>📊 Insight:</strong> Load acceptance rate shows the percentage of loads accepted by carriers. Higher rates indicate better carrier satisfaction and reliability.
              </p>
            </div>
            <div className="bg-green-500/10 border border-green-500/30 rounded-xl p-6">
              <p className="text-sm text-green-400">
                <strong>💡 Tip:</strong> Track load type distribution to understand your freight mix and plan capacity accordingly.
              </p>
            </div>
          </div>
        </>
      )}
    </div>
  )
}

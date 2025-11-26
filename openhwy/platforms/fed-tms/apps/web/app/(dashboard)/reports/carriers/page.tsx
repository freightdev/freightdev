'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useCarrierAnalytics } from '@/lib/hooks/useAnalytics'

export default function CarrierReportPage() {
  const [dateRange, setDateRange] = useState({
    startDate: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  })

  const [selectedRating, setSelectedRating] = useState<string | null>(null)

  const { data, loading, error } = useCarrierAnalytics({
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
  })

  const handleDateChange = (field: 'startDate' | 'endDate', value: string) => {
    setDateRange((prev) => ({ ...prev, [field]: value }))
  }

  const handleExportPDF = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=carriers&format=pdf&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `carriers-report-${dateRange.startDate}-to-${dateRange.endDate}.pdf`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export PDF:', err)
    }
  }

  const handleExportExcel = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=carriers&format=excel&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `carriers-report-${dateRange.startDate}-to-${dateRange.endDate}.xlsx`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export Excel:', err)
    }
  }

  const getRatingColor = (rating: number) => {
    if (rating >= 4.5) return 'text-green-400'
    if (rating >= 3.5) return 'text-blue-400'
    if (rating >= 2.5) return 'text-yellow-400'
    return 'text-red-400'
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
            <span className="text-white">Carrier Report</span>
          </div>
          <h1 className="text-3xl font-bold">Carrier Report</h1>
          <p className="text-gray-400 mt-2">Carrier performance, ratings, and reliability metrics</p>
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
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-purple-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">End Date</label>
            <input
              type="date"
              value={dateRange.endDate}
              onChange={(e) => handleDateChange('endDate', e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-purple-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Min Rating</label>
            <select
              value={selectedRating || ''}
              onChange={(e) => setSelectedRating(e.target.value || null)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-purple-500/50 transition-colors"
            >
              <option value="">All Ratings</option>
              <option value="4">4 stars & above</option>
              <option value="3.5">3.5 stars & above</option>
              <option value="3">3 stars & above</option>
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
          <p className="text-gray-400">Loading carrier data...</p>
        </div>
      )}

      {/* ERROR STATE */}
      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6">
          <p className="text-red-400">Error loading carrier data: {error}</p>
        </div>
      )}

      {/* CARRIER DATA */}
      {data && !loading && !error && (
        <>
          {/* CARRIER SUMMARY CARDS */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 rounded-xl border border-purple-500/30 p-6 space-y-3">
              <p className="text-sm text-gray-400">Total Carriers</p>
              <p className="text-4xl font-bold">{data.totalCarriers}</p>
              <p className="text-sm text-purple-400">{data.activeCarriers} active</p>
            </div>

            <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-xl border border-blue-500/30 p-6 space-y-3">
              <p className="text-sm text-gray-400">Average Rating</p>
              <p className="text-4xl font-bold">{data.averageRating.toFixed(2)}</p>
              <p className="text-sm text-blue-400">Out of 5.0 ⭐</p>
            </div>

            <div className="bg-gradient-to-br from-green-500/20 to-green-600/20 rounded-xl border border-green-500/30 p-6 space-y-3">
              <p className="text-sm text-gray-400">Active Rate</p>
              <p className="text-4xl font-bold">{((data.activeCarriers / data.totalCarriers) * 100).toFixed(1)}%</p>
              <p className="text-sm text-green-400">Actively working</p>
            </div>
          </div>

          {/* TOP CARRIERS TABLE */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 overflow-hidden">
            <div className="p-6 border-b border-white/10">
              <h2 className="text-xl font-bold">Top Performing Carriers</h2>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-white/10 bg-white/5">
                    <th className="px-6 py-4 text-left text-sm font-semibold">Carrier Name</th>
                    <th className="px-6 py-4 text-right text-sm font-semibold">Loads</th>
                    <th className="px-6 py-4 text-right text-sm font-semibold">Revenue</th>
                    <th className="px-6 py-4 text-right text-sm font-semibold">Rating</th>
                    <th className="px-6 py-4 text-right text-sm font-semibold">Acceptance</th>
                  </tr>
                </thead>
                <tbody>
                  {data.topCarriers.map((carrier, index) => (
                    <tr key={index} className="border-b border-white/10 hover:bg-white/5 transition-colors">
                      <td className="px-6 py-4 font-semibold text-white">{carrier.name}</td>
                      <td className="px-6 py-4 text-right text-gray-400">{carrier.loads}</td>
                      <td className="px-6 py-4 text-right font-semibold text-green-400">
                        ${(carrier.revenue / 1000).toFixed(1)}K
                      </td>
                      <td className={`px-6 py-4 text-right font-semibold ${getRatingColor(carrier.rating)}`}>
                        {carrier.rating.toFixed(2)} ⭐
                      </td>
                      <td className="px-6 py-4 text-right">
                        <span className="px-3 py-1 bg-green-500/20 border border-green-500/30 rounded-full text-green-400 text-sm font-semibold">
                          {(carrier.acceptanceRate * 100).toFixed(0)}%
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* RATING DISTRIBUTION */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h2 className="text-xl font-bold">Rating Distribution</h2>

            <div className="space-y-4">
              {data.ratingDistribution.map((item, index) => {
                const percentage = data.totalCarriers > 0 ? (item.count / data.totalCarriers) * 100 : 0
                return (
                  <div key={index} className="bg-white/5 rounded-lg p-4 border border-white/10">
                    <div className="flex items-center justify-between mb-3">
                      <div className="flex items-center gap-3">
                        <span className="text-lg font-semibold text-white">{item.rating}</span>
                        <p className="text-gray-400">{item.count} carriers</p>
                      </div>
                      <p className="text-2xl font-bold">{percentage.toFixed(1)}%</p>
                    </div>
                    <div className="w-full bg-white/10 rounded-full h-2 overflow-hidden">
                      <div
                        className="bg-gradient-to-r from-yellow-500 to-green-500 h-full transition-all"
                        style={{ width: `${percentage}%` }}
                      />
                    </div>
                  </div>
                )
              })}
            </div>

            <div className="text-sm text-gray-400 text-center pt-4">
              Rating distribution shows the spread of ratings across all carriers in your network
            </div>
          </div>

          {/* PERFORMANCE TREND */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h2 className="text-xl font-bold">Performance Trend</h2>

            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-white/10">
                    <th className="px-4 py-3 text-left font-semibold text-gray-400">Date</th>
                    <th className="px-4 py-3 text-right font-semibold text-gray-400">Active Carriers</th>
                    <th className="px-4 py-3 text-right font-semibold text-gray-400">Avg Rating</th>
                    <th className="px-4 py-3 text-right font-semibold text-gray-400">Rating Trend</th>
                  </tr>
                </thead>
                <tbody>
                  {data.performanceTrend.map((item, index) => {
                    const prevRating = index > 0 ? data.performanceTrend[index - 1].avgRating : item.avgRating
                    const ratingChange = item.avgRating - prevRating
                    return (
                      <tr key={index} className="border-b border-white/5 hover:bg-white/5 transition-colors">
                        <td className="px-4 py-3 text-white">{new Date(item.date).toLocaleDateString()}</td>
                        <td className="px-4 py-3 text-right font-semibold text-purple-400">{item.activeCarriers}</td>
                        <td className="px-4 py-3 text-right font-semibold text-blue-400">
                          {item.avgRating.toFixed(2)} ⭐
                        </td>
                        <td className={`px-4 py-3 text-right font-semibold ${ratingChange >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                          {ratingChange >= 0 ? '+' : ''}{ratingChange.toFixed(2)}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </div>

          {/* SUMMARY STATS */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <div>
              <p className="text-xs text-gray-400 uppercase tracking-wide">Top Carrier</p>
              <p className="text-lg font-bold mt-1 text-purple-400">
                {data.topCarriers[0]?.name || 'N/A'}
              </p>
            </div>
            <div>
              <p className="text-xs text-gray-400 uppercase tracking-wide">Highest Rated</p>
              <p className="text-lg font-bold mt-1">
                {Math.max(...data.topCarriers.map((c) => c.rating)).toFixed(2)} ⭐
              </p>
            </div>
            <div>
              <p className="text-xs text-gray-400 uppercase tracking-wide">Total Loads</p>
              <p className="text-lg font-bold mt-1 text-green-400">
                {data.topCarriers.reduce((sum, c) => sum + c.loads, 0)}
              </p>
            </div>
            <div>
              <p className="text-xs text-gray-400 uppercase tracking-wide">Report Generated</p>
              <p className="text-lg font-bold mt-1">{new Date().toLocaleDateString()}</p>
            </div>
          </div>

          {/* INFO CARDS */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-purple-500/10 border border-purple-500/30 rounded-xl p-6">
              <p className="text-sm text-purple-400">
                <strong>🏆 Insight:</strong> Top carriers show consistent performance and high acceptance rates. Consider incentivizing them for exclusive partnerships.
              </p>
            </div>
            <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
              <p className="text-sm text-blue-400">
                <strong>📈 Tip:</strong> Monitor rating trends closely. Declining ratings may indicate operational issues that need attention.
              </p>
            </div>
          </div>
        </>
      )}
    </div>
  )
}

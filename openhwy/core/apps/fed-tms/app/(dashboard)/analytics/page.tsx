'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useAnalytics } from '@/lib/hooks/useAnalytics'

export default function AnalyticsPage() {
  const [dateRange, setDateRange] = useState({
    startDate: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  })

  const { data, loading, error } = useAnalytics(dateRange)

  const handleDateChange = (field: 'startDate' | 'endDate', value: string) => {
    setDateRange((prev) => ({ ...prev, [field]: value }))
  }

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

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div>
        <h1 className="text-3xl font-bold">Analytics Dashboard</h1>
        <p className="text-gray-400 mt-2">Business insights and performance metrics</p>
      </div>

      {/* DATE RANGE FILTER */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
        <h2 className="text-lg font-bold mb-4">Date Range</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium mb-2">Start Date</label>
            <input
              type="date"
              value={dateRange.startDate}
              onChange={(e) => handleDateChange('startDate', e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">End Date</label>
            <input
              type="date"
              value={dateRange.endDate}
              onChange={(e) => handleDateChange('endDate', e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
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
          <p className="text-gray-400">Loading analytics data...</p>
        </div>
      )}

      {/* ERROR STATE */}
      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6">
          <p className="text-red-400">Error loading analytics: {error}</p>
        </div>
      )}

      {/* ANALYTICS DATA */}
      {data && !loading && !error && (
        <>
          {/* REVENUE SECTION */}
          <div className="space-y-4">
            <h2 className="text-2xl font-bold">Revenue Metrics</h2>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <div className="bg-gradient-to-br from-green-500/20 to-green-600/20 rounded-xl border border-green-500/30 p-6 space-y-3">
                <p className="text-sm text-gray-400">Total Revenue</p>
                <p className="text-3xl font-bold">{formatCurrency(data.revenue.totalRevenue)}</p>
                <p className="text-sm text-green-400">{formatPercent(data.revenue.trend)}</p>
              </div>

              <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-xl border border-blue-500/30 p-6 space-y-3">
                <p className="text-sm text-gray-400">MTD Revenue</p>
                <p className="text-3xl font-bold">{formatCurrency(data.revenue.mtdRevenue)}</p>
                <p className="text-sm text-blue-400">This Month</p>
              </div>

              <div className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 rounded-xl border border-purple-500/30 p-6 space-y-3">
                <p className="text-sm text-gray-400">YTD Revenue</p>
                <p className="text-3xl font-bold">{formatCurrency(data.revenue.ytdRevenue)}</p>
                <p className="text-sm text-purple-400">This Year</p>
              </div>

              <div className="bg-gradient-to-br from-amber-500/20 to-amber-600/20 rounded-xl border border-amber-500/30 p-6 space-y-3">
                <p className="text-sm text-gray-400">Avg Load Value</p>
                <p className="text-3xl font-bold">{formatCurrency(data.revenue.averageLoad)}</p>
                <p className="text-sm text-amber-400">Per Load</p>
              </div>
            </div>
          </div>

          {/* LOAD SECTION */}
          <div className="space-y-4">
            <h2 className="text-2xl font-bold">Load Metrics</h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-3">
                <p className="text-sm text-gray-400">Active Loads</p>
                <p className="text-3xl font-bold">{data.loads.activeLoads}</p>
                <p className="text-sm text-gray-500">{data.loads.totalLoads} Total</p>
              </div>

              <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-3">
                <p className="text-sm text-gray-400">Completed Loads</p>
                <p className="text-3xl font-bold">{data.loads.completedLoads}</p>
                <p className="text-sm text-gray-500">This Period</p>
              </div>

              <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-3">
                <p className="text-sm text-gray-400">Acceptance Rate</p>
                <p className="text-3xl font-bold">{(data.loads.acceptanceRate * 100).toFixed(1)}%</p>
                <p className="text-sm text-gray-500">Carrier Acceptance</p>
              </div>
            </div>
          </div>

          {/* CARRIER SECTION */}
          <div className="space-y-4">
            <h2 className="text-2xl font-bold">Carrier Metrics</h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-3">
                <p className="text-sm text-gray-400">Total Carriers</p>
                <p className="text-3xl font-bold">{data.carriers.totalCarriers}</p>
                <p className="text-sm text-gray-500">{data.carriers.activeCarriers} Active</p>
              </div>

              <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-3">
                <p className="text-sm text-gray-400">Approved Carriers</p>
                <p className="text-3xl font-bold">{data.carriers.approvedCarriers}</p>
                <p className="text-sm text-gray-500">Ready to Work</p>
              </div>

              <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-3">
                <p className="text-sm text-gray-400">Avg Rating</p>
                <p className="text-3xl font-bold">{data.carriers.averageRating.toFixed(2)}/5</p>
                <p className="text-sm text-gray-500">Stars</p>
              </div>
            </div>
          </div>

          {/* TOP CARRIERS */}
          <div className="space-y-4">
            <h2 className="text-2xl font-bold">Top Carriers</h2>

            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 overflow-hidden">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-white/10 bg-white/5">
                    <th className="px-6 py-4 text-left text-sm font-semibold">Carrier</th>
                    <th className="px-6 py-4 text-left text-sm font-semibold">Loads</th>
                    <th className="px-6 py-4 text-left text-sm font-semibold">Revenue</th>
                    <th className="px-6 py-4 text-left text-sm font-semibold">Rating</th>
                  </tr>
                </thead>
                <tbody>
                  {data.topCarriers.map((carrier, index) => (
                    <tr key={index} className="border-b border-white/10 hover:bg-white/5 transition-colors">
                      <td className="px-6 py-4 font-semibold">{carrier.name}</td>
                      <td className="px-6 py-4 text-gray-400">{carrier.loads}</td>
                      <td className="px-6 py-4 font-semibold">{formatCurrency(carrier.revenue)}</td>
                      <td className="px-6 py-4">
                        <span className={`text-sm font-semibold ${carrier.rating >= 4 ? 'text-green-400' : carrier.rating >= 3 ? 'text-yellow-400' : 'text-red-400'}`}>
                          {carrier.rating.toFixed(2)} ⭐
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* QUICK LINKS TO DETAILED REPORTS */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Link
              href="/dashboard/reports/revenue"
              className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 hover:border-green-500/50 p-6 transition-all group"
            >
              <h3 className="text-lg font-bold group-hover:text-green-400 transition-colors">Revenue Report</h3>
              <p className="text-sm text-gray-400 mt-2">Detailed revenue analysis and trends</p>
            </Link>

            <Link
              href="/dashboard/reports/loads"
              className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 hover:border-blue-500/50 p-6 transition-all group"
            >
              <h3 className="text-lg font-bold group-hover:text-blue-400 transition-colors">Load Report</h3>
              <p className="text-sm text-gray-400 mt-2">Load volume and distribution analysis</p>
            </Link>

            <Link
              href="/dashboard/reports/carriers"
              className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 hover:border-purple-500/50 p-6 transition-all group"
            >
              <h3 className="text-lg font-bold group-hover:text-purple-400 transition-colors">Carrier Report</h3>
              <p className="text-sm text-gray-400 mt-2">Carrier performance and rankings</p>
            </Link>
          </div>
        </>
      )}
    </div>
  )
}

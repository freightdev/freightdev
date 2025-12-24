'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useRevenueAnalytics } from '@/lib/hooks/useAnalytics'

export default function RevenueReportPage() {
  const [dateRange, setDateRange] = useState({
    startDate: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  })

  const [selectedCarrier, setSelectedCarrier] = useState<string | null>(null)

  const { data, loading, error } = useRevenueAnalytics({
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
    carrierId: selectedCarrier || undefined,
  })

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

  const handleExportPDF = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=revenue&format=pdf&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `revenue-report-${dateRange.startDate}-to-${dateRange.endDate}.pdf`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export PDF:', err)
    }
  }

  const handleExportExcel = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=revenue&format=excel&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `revenue-report-${dateRange.startDate}-to-${dateRange.endDate}.xlsx`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export Excel:', err)
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
            <span className="text-white">Revenue Report</span>
          </div>
          <h1 className="text-3xl font-bold">Revenue Report</h1>
          <p className="text-gray-400 mt-2">Detailed revenue analysis, trends, and commission breakdown</p>
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
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-green-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">End Date</label>
            <input
              type="date"
              value={dateRange.endDate}
              onChange={(e) => handleDateChange('endDate', e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-green-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Carrier</label>
            <select
              value={selectedCarrier || ''}
              onChange={(e) => setSelectedCarrier(e.target.value || null)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-green-500/50 transition-colors"
            >
              <option value="">All Carriers</option>
              <option value="carrier1">Express Logistics</option>
              <option value="carrier2">FastFreight Inc</option>
              <option value="carrier3">TrueFreight Co</option>
              <option value="carrier4">Bulk Haulers Ltd</option>
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
          <p className="text-gray-400">Loading revenue data...</p>
        </div>
      )}

      {/* ERROR STATE */}
      {error && (
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6">
          <p className="text-red-400">Error loading revenue data: {error}</p>
        </div>
      )}

      {/* REVENUE DATA */}
      {data && !loading && !error && (
        <>
          {/* REVENUE SUMMARY CARDS */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-gradient-to-br from-green-500/20 to-green-600/20 rounded-xl border border-green-500/30 p-6 space-y-3">
              <p className="text-sm text-gray-400">Total Revenue</p>
              <p className="text-4xl font-bold">{formatCurrency(data.totalRevenue)}</p>
              <p className="text-sm text-green-400">Complete period</p>
            </div>

            <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-xl border border-blue-500/30 p-6 space-y-3">
              <p className="text-sm text-gray-400">Month-to-Date</p>
              <p className="text-4xl font-bold">{formatCurrency(data.mtdRevenue)}</p>
              <p className="text-sm text-blue-400">Current month</p>
            </div>

            <div className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 rounded-xl border border-purple-500/30 p-6 space-y-3">
              <p className="text-sm text-gray-400">Total Commission</p>
              <p className="text-4xl font-bold">{formatCurrency(data.trend.reduce((sum, item) => sum + item.commission, 0))}</p>
              <p className="text-sm text-purple-400">All commissions</p>
            </div>
          </div>

          {/* REVENUE TREND SECTION */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h2 className="text-xl font-bold">Revenue Trend</h2>

            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-white/10">
                    <th className="px-4 py-3 text-left font-semibold text-gray-400">Date</th>
                    <th className="px-4 py-3 text-right font-semibold text-gray-400">Revenue</th>
                    <th className="px-4 py-3 text-right font-semibold text-gray-400">Commission</th>
                    <th className="px-4 py-3 text-right font-semibold text-gray-400">Net Revenue</th>
                  </tr>
                </thead>
                <tbody>
                  {data.trend.map((item, index) => (
                    <tr key={index} className="border-b border-white/5 hover:bg-white/5 transition-colors">
                      <td className="px-4 py-3 text-white">{new Date(item.date).toLocaleDateString()}</td>
                      <td className="px-4 py-3 text-right font-semibold text-green-400">{formatCurrency(item.revenue)}</td>
                      <td className="px-4 py-3 text-right font-semibold text-purple-400">{formatCurrency(item.commission)}</td>
                      <td className="px-4 py-3 text-right font-semibold text-blue-400">{formatCurrency(item.revenue - item.commission)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="text-sm text-gray-400 text-center">
              {data.trend.length} days of revenue data shown above
            </div>
          </div>

          {/* REVENUE BY CARRIER */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h2 className="text-xl font-bold">Revenue by Carrier</h2>

            <div className="space-y-3">
              {data.byCarrier.map((carrier, index) => (
                <div key={index} className="bg-white/5 rounded-lg p-4 border border-white/10 hover:border-white/20 transition-colors">
                  <div className="flex items-center justify-between mb-3">
                    <div>
                      <p className="font-semibold text-white">{carrier.carrier}</p>
                      <p className="text-sm text-gray-400">{carrier.percentage.toFixed(1)}% of total</p>
                    </div>
                    <p className="text-2xl font-bold text-green-400">{formatCurrency(carrier.revenue)}</p>
                  </div>
                  <div className="w-full bg-white/10 rounded-full h-2 overflow-hidden">
                    <div
                      className="bg-gradient-to-r from-green-500 to-green-600 h-full"
                      style={{ width: `${carrier.percentage}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>

            <div className="grid grid-cols-2 md:grid-cols-4 gap-3 pt-4 border-t border-white/10">
              <div>
                <p className="text-xs text-gray-400 uppercase tracking-wide">Top Carrier</p>
                <p className="text-lg font-bold text-green-400">
                  {data.byCarrier[0]?.carrier || 'N/A'}
                </p>
              </div>
              <div>
                <p className="text-xs text-gray-400 uppercase tracking-wide">Total Carriers</p>
                <p className="text-lg font-bold">{data.byCarrier.length}</p>
              </div>
              <div>
                <p className="text-xs text-gray-400 uppercase tracking-wide">Avg per Carrier</p>
                <p className="text-lg font-bold text-blue-400">
                  {formatCurrency(data.totalRevenue / data.byCarrier.length)}
                </p>
              </div>
              <div>
                <p className="text-xs text-gray-400 uppercase tracking-wide">Report Generated</p>
                <p className="text-lg font-bold">{new Date().toLocaleDateString()}</p>
              </div>
            </div>
          </div>

          {/* INFO CARDS */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="bg-green-500/10 border border-green-500/30 rounded-xl p-6">
              <p className="text-sm text-green-400">
                <strong>💡 Insight:</strong> Revenue trends are calculated daily. Use date filters to compare specific periods and identify seasonal patterns.
              </p>
            </div>
            <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
              <p className="text-sm text-blue-400">
                <strong>📊 Tip:</strong> Export this report as PDF for presentations or as Excel for further analysis in your preferred tools.
              </p>
            </div>
          </div>
        </>
      )}
    </div>
  )
}

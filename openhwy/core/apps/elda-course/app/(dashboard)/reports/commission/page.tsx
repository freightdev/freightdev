'use client'

import React, { useState } from 'react'
import Link from 'next/link'

export default function CommissionReportPage() {
  const [dateRange, setDateRange] = useState({
    startDate: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  })

  const [selectedDispatcher, setSelectedDispatcher] = useState<string | null>(null)

  const handleDateChange = (field: 'startDate' | 'endDate', value: string) => {
    setDateRange((prev) => ({ ...prev, [field]: value }))
  }

  const handleExportPDF = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=commission&format=pdf&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `commission-report-${dateRange.startDate}-to-${dateRange.endDate}.pdf`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export PDF:', err)
    }
  }

  const handleExportExcel = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=commission&format=excel&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `commission-report-${dateRange.startDate}-to-${dateRange.endDate}.xlsx`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export Excel:', err)
    }
  }

  // Sample commission data
  const commissionData = {
    totalCommissions: 245500,
    mtdCommissions: 45230,
    avgCommissionRate: 8.5,
    totalDispatchers: 12,
    topDispatcher: {
      name: 'John Smith',
      earnings: 15800,
      loads: 248,
      rate: 8.5,
    },
  }

  const dispatcherEarnings = [
    { id: 1, name: 'John Smith', loads: 248, revenue: 185600, commissionRate: 8.5, earnings: 15800, trend: '+12%' },
    { id: 2, name: 'Sarah Johnson', loads: 198, revenue: 148000, commissionRate: 8.0, earnings: 11840, trend: '+8%' },
    { id: 3, name: 'Michael Brown', loads: 164, revenue: 122800, commissionRate: 7.5, earnings: 9210, trend: '-2%' },
    { id: 4, name: 'Emily Davis', loads: 156, revenue: 117000, commissionRate: 8.5, earnings: 9945, trend: '+15%' },
    { id: 5, name: 'David Wilson', loads: 142, revenue: 106500, commissionRate: 7.0, earnings: 7455, trend: '+5%' },
  ]

  const commissionTrend = [
    { date: '2024-10-21', total: 8500, count: 42, avg: 202.4 },
    { date: '2024-10-22', total: 9200, count: 45, avg: 204.4 },
    { date: '2024-10-23', total: 8900, count: 44, avg: 202.3 },
    { date: '2024-10-24', total: 9600, count: 48, avg: 200.0 },
    { date: '2024-10-25', total: 10200, count: 50, avg: 204.0 },
  ]

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
    }).format(value)
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
            <span className="text-white">Commission Report</span>
          </div>
          <h1 className="text-3xl font-bold">Commission Report</h1>
          <p className="text-gray-400 mt-2">Commission payments, rates, and dispatcher earnings</p>
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
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-amber-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">End Date</label>
            <input
              type="date"
              value={dateRange.endDate}
              onChange={(e) => handleDateChange('endDate', e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-amber-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Dispatcher</label>
            <select
              value={selectedDispatcher || ''}
              onChange={(e) => setSelectedDispatcher(e.target.value || null)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-amber-500/50 transition-colors"
            >
              <option value="">All Dispatchers</option>
              <option value="john">John Smith</option>
              <option value="sarah">Sarah Johnson</option>
              <option value="michael">Michael Brown</option>
              <option value="emily">Emily Davis</option>
              <option value="david">David Wilson</option>
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

      {/* COMMISSION SUMMARY CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-gradient-to-br from-amber-500/20 to-amber-600/20 rounded-xl border border-amber-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Total Commissions</p>
          <p className="text-4xl font-bold">{formatCurrency(commissionData.totalCommissions)}</p>
          <p className="text-sm text-amber-400">Complete period</p>
        </div>

        <div className="bg-gradient-to-br from-orange-500/20 to-orange-600/20 rounded-xl border border-orange-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">MTD Commissions</p>
          <p className="text-4xl font-bold">{formatCurrency(commissionData.mtdCommissions)}</p>
          <p className="text-sm text-orange-400">Current month</p>
        </div>

        <div className="bg-gradient-to-br from-purple-500/20 to-purple-600/20 rounded-xl border border-purple-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Avg Commission Rate</p>
          <p className="text-4xl font-bold">{commissionData.avgCommissionRate}%</p>
          <p className="text-sm text-purple-400">Platform average</p>
        </div>

        <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-xl border border-blue-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Total Dispatchers</p>
          <p className="text-4xl font-bold">{commissionData.totalDispatchers}</p>
          <p className="text-sm text-blue-400">Active earners</p>
        </div>
      </div>

      {/* TOP DISPATCHER CARD */}
      <div className="bg-gradient-to-br from-green-500/20 to-green-600/20 rounded-xl border border-green-500/30 p-6 space-y-4">
        <h2 className="text-lg font-bold">Top Dispatcher</h2>
        <div className="flex items-center justify-between">
          <div>
            <p className="text-2xl font-bold text-white">{commissionData.topDispatcher.name}</p>
            <p className="text-sm text-gray-400 mt-1">{commissionData.topDispatcher.loads} loads processed</p>
          </div>
          <div className="text-right">
            <p className="text-3xl font-bold text-green-400">{formatCurrency(commissionData.topDispatcher.earnings)}</p>
            <p className="text-sm text-gray-400 mt-1">@{commissionData.topDispatcher.rate}% commission</p>
          </div>
        </div>
      </div>

      {/* DISPATCHER EARNINGS TABLE */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 overflow-hidden">
        <div className="p-6 border-b border-white/10">
          <h2 className="text-xl font-bold">Dispatcher Earnings</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-white/10 bg-white/5">
                <th className="px-6 py-4 text-left text-sm font-semibold">Dispatcher</th>
                <th className="px-6 py-4 text-right text-sm font-semibold">Loads</th>
                <th className="px-6 py-4 text-right text-sm font-semibold">Revenue</th>
                <th className="px-6 py-4 text-right text-sm font-semibold">Rate</th>
                <th className="px-6 py-4 text-right text-sm font-semibold">Earnings</th>
                <th className="px-6 py-4 text-right text-sm font-semibold">Trend</th>
              </tr>
            </thead>
            <tbody>
              {dispatcherEarnings.map((dispatcher) => (
                <tr key={dispatcher.id} className="border-b border-white/10 hover:bg-white/5 transition-colors">
                  <td className="px-6 py-4 font-semibold text-white">{dispatcher.name}</td>
                  <td className="px-6 py-4 text-right text-gray-400">{dispatcher.loads}</td>
                  <td className="px-6 py-4 text-right font-semibold text-green-400">{formatCurrency(dispatcher.revenue)}</td>
                  <td className="px-6 py-4 text-right text-gray-400">{dispatcher.commissionRate}%</td>
                  <td className="px-6 py-4 text-right font-semibold text-amber-400">{formatCurrency(dispatcher.earnings)}</td>
                  <td className={`px-6 py-4 text-right font-semibold ${dispatcher.trend.startsWith('+') ? 'text-green-400' : 'text-red-400'}`}>
                    {dispatcher.trend}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* COMMISSION TREND */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Daily Commission Trend</h2>

        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-white/10">
                <th className="px-4 py-3 text-left font-semibold text-gray-400">Date</th>
                <th className="px-4 py-3 text-right font-semibold text-gray-400">Total Commission</th>
                <th className="px-4 py-3 text-right font-semibold text-gray-400">Loads</th>
                <th className="px-4 py-3 text-right font-semibold text-gray-400">Avg per Load</th>
              </tr>
            </thead>
            <tbody>
              {commissionTrend.map((item, index) => (
                <tr key={index} className="border-b border-white/5 hover:bg-white/5 transition-colors">
                  <td className="px-4 py-3 text-white">{new Date(item.date).toLocaleDateString()}</td>
                  <td className="px-4 py-3 text-right font-semibold text-amber-400">{formatCurrency(item.total)}</td>
                  <td className="px-4 py-3 text-right text-gray-400">{item.count}</td>
                  <td className="px-4 py-3 text-right font-semibold text-purple-400">{formatCurrency(item.avg)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* COMMISSION RATE BREAKDOWN */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Commission Rate Distribution</h2>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div className="bg-white/5 rounded-lg p-4 border border-white/10">
            <p className="text-sm text-gray-400 uppercase tracking-wide">3% Rate</p>
            <p className="text-2xl font-bold mt-2">2 dispatchers</p>
            <p className="text-xs text-gray-500 mt-2">Paperwork only</p>
          </div>
          <div className="bg-white/5 rounded-lg p-4 border border-white/10">
            <p className="text-sm text-gray-400 uppercase tracking-wide">4% Rate</p>
            <p className="text-2xl font-bold mt-2">1 dispatcher</p>
            <p className="text-xs text-gray-500 mt-2">Half commission</p>
          </div>
          <div className="bg-white/5 rounded-lg p-4 border border-white/10">
            <p className="text-sm text-gray-400 uppercase tracking-wide">8% Rate</p>
            <p className="text-2xl font-bold mt-2">7 dispatchers</p>
            <p className="text-xs text-gray-500 mt-2">Full dispatcher</p>
          </div>
          <div className="bg-white/5 rounded-lg p-4 border border-white/10">
            <p className="text-sm text-gray-400 uppercase tracking-wide">12% Rate</p>
            <p className="text-2xl font-bold mt-2">2 dispatchers</p>
            <p className="text-xs text-gray-500 mt-2">Load finder</p>
          </div>
        </div>
      </div>

      {/* INFO CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-amber-500/10 border border-amber-500/30 rounded-xl p-6">
          <p className="text-sm text-amber-400">
            <strong>💰 Insight:</strong> Commission earnings reflect dispatcher productivity. Higher rates incentivize load sourcing but may reduce volume.
          </p>
        </div>
        <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
          <p className="text-sm text-blue-400">
            <strong>📊 Tip:</strong> Monitor dispatcher earnings trends to ensure fair compensation and maintain team motivation and retention.
          </p>
        </div>
      </div>
    </div>
  )
}

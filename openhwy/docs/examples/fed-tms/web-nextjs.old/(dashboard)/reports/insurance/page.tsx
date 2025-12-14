'use client'

import React, { useState } from 'react'
import Link from 'next/link'

export default function InsuranceComplianceReportPage() {
  const [dateRange, setDateRange] = useState({
    startDate: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  })

  const handleDateChange = (field: 'startDate' | 'endDate', value: string) => {
    setDateRange((prev) => ({ ...prev, [field]: value }))
  }

  const handleExportPDF = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=insurance&format=pdf&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `insurance-report-${dateRange.startDate}-to-${dateRange.endDate}.pdf`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export PDF:', err)
    }
  }

  const handleExportExcel = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=insurance&format=excel&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `insurance-report-${dateRange.startDate}-to-${dateRange.endDate}.xlsx`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export Excel:', err)
    }
  }

  // Sample insurance data
  const insuranceData = {
    totalCarriers: 342,
    currentCoverage: 328,
    expiringIn30Days: 9,
    expired: 5,
    complianceRate: 95.9,
  }

  const carrierInsuranceStatus = [
    {
      id: 1,
      name: 'Express Logistics',
      mcNumber: 'MC-123456',
      policyExpiry: '2025-03-15',
      status: 'current',
      coverage: '$2,000,000',
      lastVerified: '2024-11-20',
    },
    {
      id: 2,
      name: 'FastFreight Inc',
      mcNumber: 'MC-234567',
      policyExpiry: '2024-12-10',
      status: 'expiring',
      coverage: '$1,500,000',
      lastVerified: '2024-11-18',
    },
    {
      id: 3,
      name: 'TrueFreight Co',
      mcNumber: 'MC-345678',
      policyExpiry: '2024-10-25',
      status: 'expired',
      coverage: '$2,000,000',
      lastVerified: '2024-11-01',
    },
    {
      id: 4,
      name: 'Bulk Haulers Ltd',
      mcNumber: 'MC-456789',
      policyExpiry: '2025-06-30',
      status: 'current',
      coverage: '$3,000,000',
      lastVerified: '2024-11-22',
    },
    {
      id: 5,
      name: 'Southern Transport',
      mcNumber: 'MC-567890',
      policyExpiry: '2025-01-20',
      status: 'current',
      coverage: '$1,500,000',
      lastVerified: '2024-11-21',
    },
  ]

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'current':
        return { bg: 'bg-green-500/20', border: 'border-green-500/30', text: 'text-green-400' }
      case 'expiring':
        return { bg: 'bg-yellow-500/20', border: 'border-yellow-500/30', text: 'text-yellow-400' }
      case 'expired':
        return { bg: 'bg-red-500/20', border: 'border-red-500/30', text: 'text-red-400' }
      default:
        return { bg: 'bg-white/5', border: 'border-white/10', text: 'text-gray-400' }
    }
  }

  const getStatusBadgeText = (status: string) => {
    switch (status) {
      case 'current':
        return '✓ Current'
      case 'expiring':
        return '⚠ Expiring Soon'
      case 'expired':
        return '✗ Expired'
      default:
        return 'Unknown'
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
            <span className="text-white">Insurance Compliance</span>
          </div>
          <h1 className="text-3xl font-bold">Insurance Compliance Report</h1>
          <p className="text-gray-400 mt-2">Insurance verification status and compliance tracking</p>
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

      {/* DATE RANGE */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-lg font-bold">Report Period</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium mb-2">Start Date</label>
            <input
              type="date"
              value={dateRange.startDate}
              onChange={(e) => handleDateChange('startDate', e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-red-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">End Date</label>
            <input
              type="date"
              value={dateRange.endDate}
              onChange={(e) => handleDateChange('endDate', e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-red-500/50 transition-colors"
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

      {/* COMPLIANCE SUMMARY CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-gradient-to-br from-red-500/20 to-red-600/20 rounded-xl border border-red-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Total Carriers</p>
          <p className="text-4xl font-bold">{insuranceData.totalCarriers}</p>
          <p className="text-sm text-red-400">Active network</p>
        </div>

        <div className="bg-gradient-to-br from-green-500/20 to-green-600/20 rounded-xl border border-green-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Current Coverage</p>
          <p className="text-4xl font-bold">{insuranceData.currentCoverage}</p>
          <p className="text-sm text-green-400">Insurance valid</p>
        </div>

        <div className="bg-gradient-to-br from-yellow-500/20 to-yellow-600/20 rounded-xl border border-yellow-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Expiring in 30 Days</p>
          <p className="text-4xl font-bold text-yellow-400">{insuranceData.expiringIn30Days}</p>
          <p className="text-sm text-yellow-400">Action required</p>
        </div>

        <div className="bg-gradient-to-br from-red-600/20 to-red-700/20 rounded-xl border border-red-600/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Expired</p>
          <p className="text-4xl font-bold text-red-400">{insuranceData.expired}</p>
          <p className="text-sm text-red-400">Not authorized</p>
        </div>
      </div>

      {/* COMPLIANCE RATE */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-2xl font-bold">Compliance Rate</h2>
            <p className="text-gray-400 mt-1">Percentage of carriers with current insurance</p>
          </div>
          <p className="text-5xl font-bold text-green-400">{insuranceData.complianceRate}%</p>
        </div>

        <div className="w-full bg-white/10 rounded-full h-4 overflow-hidden">
          <div
            className="bg-gradient-to-r from-green-500 to-green-600 h-full transition-all"
            style={{ width: `${insuranceData.complianceRate}%` }}
          />
        </div>

        <div className="grid grid-cols-3 gap-4 pt-4 text-sm">
          <div>
            <p className="text-gray-400">Target Rate</p>
            <p className="text-lg font-bold mt-1">100%</p>
          </div>
          <div>
            <p className="text-gray-400">Current Rate</p>
            <p className="text-lg font-bold mt-1 text-green-400">{insuranceData.complianceRate}%</p>
          </div>
          <div>
            <p className="text-gray-400">Gap</p>
            <p className="text-lg font-bold mt-1 text-yellow-400">{(100 - insuranceData.complianceRate).toFixed(1)}%</p>
          </div>
        </div>
      </div>

      {/* CARRIER INSURANCE STATUS TABLE */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 overflow-hidden">
        <div className="p-6 border-b border-white/10">
          <h2 className="text-xl font-bold">Carrier Insurance Status</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-white/10 bg-white/5">
                <th className="px-6 py-4 text-left text-sm font-semibold">Carrier</th>
                <th className="px-6 py-4 text-left text-sm font-semibold">MC Number</th>
                <th className="px-6 py-4 text-right text-sm font-semibold">Coverage</th>
                <th className="px-6 py-4 text-center text-sm font-semibold">Status</th>
                <th className="px-6 py-4 text-right text-sm font-semibold">Expires</th>
                <th className="px-6 py-4 text-right text-sm font-semibold">Last Verified</th>
              </tr>
            </thead>
            <tbody>
              {carrierInsuranceStatus.map((carrier) => {
                const statusColors = getStatusColor(carrier.status)
                return (
                  <tr key={carrier.id} className="border-b border-white/10 hover:bg-white/5 transition-colors">
                    <td className="px-6 py-4 font-semibold text-white">{carrier.name}</td>
                    <td className="px-6 py-4 text-gray-400 font-mono text-sm">{carrier.mcNumber}</td>
                    <td className="px-6 py-4 text-right text-gray-400">{carrier.coverage}</td>
                    <td className="px-6 py-4 text-center">
                      <span className={`px-3 py-1 ${statusColors.bg} ${statusColors.border} rounded-full ${statusColors.text} text-xs font-semibold border`}>
                        {getStatusBadgeText(carrier.status)}
                      </span>
                    </td>
                    <td className={`px-6 py-4 text-right font-semibold ${carrier.status === 'expired' ? 'text-red-400' : carrier.status === 'expiring' ? 'text-yellow-400' : 'text-green-400'}`}>
                      {new Date(carrier.policyExpiry).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 text-right text-gray-400">{new Date(carrier.lastVerified).toLocaleDateString()}</td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* REQUIRED DOCUMENTATION CHECKLIST */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Required Documentation</h2>

        <div className="space-y-3">
          {[
            { name: 'Certificate of Insurance (COI)', requirement: 'Primary liability coverage', status: 'complete' },
            { name: 'Auto Policy Declaration', requirement: 'Current policy proof', status: 'complete' },
            { name: 'Worker\'s Compensation (if applicable)', requirement: 'Employee coverage', status: 'complete' },
            { name: 'Cargo Insurance', requirement: 'Freight protection', status: 'pending' },
            { name: 'General Liability', requirement: 'Business protection', status: 'complete' },
          ].map((doc, index) => (
            <div key={index} className="flex items-center justify-between p-4 bg-white/5 rounded-lg border border-white/10">
              <div>
                <p className="font-semibold text-white">{doc.name}</p>
                <p className="text-sm text-gray-400">{doc.requirement}</p>
              </div>
              <span className={`px-3 py-1 rounded-full text-xs font-semibold ${doc.status === 'complete' ? 'bg-green-500/20 text-green-400 border border-green-500/30' : 'bg-yellow-500/20 text-yellow-400 border border-yellow-500/30'}`}>
                {doc.status === 'complete' ? '✓ Complete' : '⚠ Pending'}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* COMPLIANCE ACTIONS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Recommended Actions</h2>

        <div className="space-y-3">
          <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-4 flex items-start gap-4">
            <span className="text-2xl">⚠️</span>
            <div>
              <p className="font-semibold text-white">5 Carriers with Expired Insurance</p>
              <p className="text-sm text-gray-400 mt-1">Contact these carriers immediately to renew coverage or suspend operations.</p>
            </div>
          </div>

          <div className="bg-yellow-500/10 border border-yellow-500/30 rounded-lg p-4 flex items-start gap-4">
            <span className="text-2xl">⏰</span>
            <div>
              <p className="font-semibold text-white">9 Carriers Expiring in 30 Days</p>
              <p className="text-sm text-gray-400 mt-1">Send renewal reminders to ensure continuous coverage compliance.</p>
            </div>
          </div>

          <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4 flex items-start gap-4">
            <span className="text-2xl">📋</span>
            <div>
              <p className="font-semibold text-white">Schedule Quarterly Audits</p>
              <p className="text-sm text-gray-400 mt-1">Verify all carriers maintain current insurance at least every 90 days.</p>
            </div>
          </div>
        </div>
      </div>

      {/* INFO CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6">
          <p className="text-sm text-red-400">
            <strong>⚖️ Compliance Requirement:</strong> All carriers must maintain valid commercial auto insurance with minimum coverage limits as per FMCSA regulations.
          </p>
        </div>
        <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
          <p className="text-sm text-blue-400">
            <strong>📊 Tip:</strong> Automate insurance verification through third-party providers to ensure real-time compliance monitoring.
          </p>
        </div>
      </div>
    </div>
  )
}

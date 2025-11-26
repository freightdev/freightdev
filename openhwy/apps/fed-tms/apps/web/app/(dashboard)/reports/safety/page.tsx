'use client'

import React, { useState } from 'react'
import Link from 'next/link'

export default function SafetyComplianceReportPage() {
  const [dateRange, setDateRange] = useState({
    startDate: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  })

  const handleDateChange = (field: 'startDate' | 'endDate', value: string) => {
    setDateRange((prev) => ({ ...prev, [field]: value }))
  }

  const handleExportPDF = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=safety&format=pdf&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `safety-report-${dateRange.startDate}-to-${dateRange.endDate}.pdf`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export PDF:', err)
    }
  }

  const handleExportExcel = async () => {
    try {
      const response = await fetch(`/api/reports/generate?type=safety&format=excel&startDate=${dateRange.startDate}&endDate=${dateRange.endDate}`)
      if (response.ok) {
        const blob = await response.blob()
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `safety-report-${dateRange.startDate}-to-${dateRange.endDate}.xlsx`
        a.click()
        URL.revokeObjectURL(url)
      }
    } catch (err) {
      console.error('Failed to export Excel:', err)
    }
  }

  // Sample safety data
  const safetyData = {
    totalCarriers: 342,
    satisfactory: 298,
    conditional: 36,
    unsatisfactory: 8,
    avgSafetyScore: 4.2,
    complaintRate: 0.8,
    accidentRate: 1.2,
  }

  const safetyRatings = [
    { name: 'Satisfactory', count: 298, percentage: 87.1, description: 'Good safety record' },
    { name: 'Conditional', count: 36, percentage: 10.5, description: 'Some violations found' },
    { name: 'Unsatisfactory', count: 8, percentage: 2.3, description: 'Safety violations' },
  ]

  const topViolations = [
    { violation: 'Speeding', count: 24, percentage: 28.2, severity: 'medium' },
    { violation: 'Vehicle Maintenance', count: 18, percentage: 21.2, severity: 'high' },
    { violation: 'Hours of Service', count: 15, percentage: 17.6, severity: 'high' },
    { violation: 'Seatbelt Compliance', count: 12, percentage: 14.1, severity: 'medium' },
    { violation: 'Hazmat Documentation', count: 16, percentage: 18.8, severity: 'high' },
  ]

  const carrierSafetyRatings = [
    {
      id: 1,
      name: 'Express Logistics',
      rating: 'Satisfactory',
      score: 4.8,
      lastInspection: '2024-11-10',
      violations: 0,
      complaints: 0,
    },
    {
      id: 2,
      name: 'FastFreight Inc',
      rating: 'Satisfactory',
      score: 4.5,
      lastInspection: '2024-10-28',
      violations: 1,
      complaints: 0,
    },
    {
      id: 3,
      name: 'TrueFreight Co',
      rating: 'Conditional',
      score: 3.2,
      lastInspection: '2024-09-15',
      violations: 3,
      complaints: 1,
    },
    {
      id: 4,
      name: 'Bulk Haulers Ltd',
      rating: 'Satisfactory',
      score: 4.6,
      lastInspection: '2024-11-05',
      violations: 0,
      complaints: 0,
    },
    {
      id: 5,
      name: 'Southern Transport',
      rating: 'Unsatisfactory',
      score: 2.1,
      lastInspection: '2024-08-30',
      violations: 8,
      complaints: 3,
    },
  ]

  const getSafetyColor = (rating: string | number) => {
    const ratingStr = typeof rating === 'string' ? rating : rating.toString()
    if (ratingStr.includes('Satisfactory') && !ratingStr.includes('Unsatisfactory')) {
      return { bg: 'bg-green-500/20', border: 'border-green-500/30', text: 'text-green-400' }
    } else if (ratingStr.includes('Conditional')) {
      return { bg: 'bg-yellow-500/20', border: 'border-yellow-500/30', text: 'text-yellow-400' }
    } else {
      return { bg: 'bg-red-500/20', border: 'border-red-500/30', text: 'text-red-400' }
    }
  }

  const getViolationColor = (severity: string) => {
    switch (severity) {
      case 'high':
        return 'text-red-400'
      case 'medium':
        return 'text-yellow-400'
      default:
        return 'text-blue-400'
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
            <span className="text-white">Safety & Compliance</span>
          </div>
          <h1 className="text-3xl font-bold">Safety & Compliance Report</h1>
          <p className="text-gray-400 mt-2">Safety ratings, compliance records, and certifications</p>
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
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-cyan-500/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">End Date</label>
            <input
              type="date"
              value={dateRange.endDate}
              onChange={(e) => handleDateChange('endDate', e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-cyan-500/50 transition-colors"
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

      {/* SAFETY SUMMARY CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-gradient-to-br from-cyan-500/20 to-cyan-600/20 rounded-xl border border-cyan-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Total Carriers</p>
          <p className="text-4xl font-bold">{safetyData.totalCarriers}</p>
          <p className="text-sm text-cyan-400">Active network</p>
        </div>

        <div className="bg-gradient-to-br from-green-500/20 to-green-600/20 rounded-xl border border-green-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Avg Safety Score</p>
          <p className="text-4xl font-bold">{safetyData.avgSafetyScore.toFixed(1)}</p>
          <p className="text-sm text-green-400">Out of 5.0 ⭐</p>
        </div>

        <div className="bg-gradient-to-br from-yellow-500/20 to-yellow-600/20 rounded-xl border border-yellow-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Complaint Rate</p>
          <p className="text-4xl font-bold text-yellow-400">{safetyData.complaintRate}%</p>
          <p className="text-sm text-yellow-400">Of deliveries</p>
        </div>

        <div className="bg-gradient-to-br from-red-500/20 to-red-600/20 rounded-xl border border-red-500/30 p-6 space-y-3">
          <p className="text-sm text-gray-400">Accident Rate</p>
          <p className="text-4xl font-bold text-red-400">{safetyData.accidentRate}%</p>
          <p className="text-sm text-red-400">Reportable incidents</p>
        </div>
      </div>

      {/* SAFETY RATING DISTRIBUTION */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Safety Rating Distribution</h2>

        <div className="space-y-4">
          {safetyRatings.map((rating, index) => {
            const colors = getSafetyColor(rating.name)
            return (
              <div key={index} className={`${colors.bg} ${colors.border} rounded-lg p-4 border transition-colors`}>
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <p className={`font-semibold ${colors.text}`}>{rating.name}</p>
                    <p className="text-sm text-gray-400">{rating.description}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-2xl font-bold">{rating.count}</p>
                    <p className={`text-sm ${colors.text}`}>{rating.percentage}%</p>
                  </div>
                </div>
                <div className="w-full bg-white/10 rounded-full h-2 overflow-hidden">
                  <div
                    className={`h-full transition-all ${
                      rating.name.includes('Satisfactory') && !rating.name.includes('Unsatisfactory')
                        ? 'bg-gradient-to-r from-green-500 to-green-600'
                        : rating.name.includes('Conditional')
                          ? 'bg-gradient-to-r from-yellow-500 to-yellow-600'
                          : 'bg-gradient-to-r from-red-500 to-red-600'
                    }`}
                    style={{ width: `${rating.percentage}%` }}
                  />
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {/* TOP VIOLATIONS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Top Safety Violations</h2>

        <div className="space-y-3">
          {topViolations.map((violation, index) => (
            <div key={index} className="bg-white/5 rounded-lg p-4 border border-white/10 hover:border-white/20 transition-colors">
              <div className="flex items-center justify-between mb-3">
                <div>
                  <p className="font-semibold text-white">{violation.violation}</p>
                  <p className={`text-sm ${getViolationColor(violation.severity)}`}>
                    {violation.severity.charAt(0).toUpperCase() + violation.severity.slice(1)} Severity
                  </p>
                </div>
                <div className="text-right">
                  <p className="text-2xl font-bold">{violation.count}</p>
                  <p className="text-sm text-gray-400">{violation.percentage}% of total</p>
                </div>
              </div>
              <div className="w-full bg-white/10 rounded-full h-2 overflow-hidden">
                <div
                  className={`h-full transition-all ${
                    violation.severity === 'high'
                      ? 'bg-gradient-to-r from-red-500 to-red-600'
                      : violation.severity === 'medium'
                        ? 'bg-gradient-to-r from-yellow-500 to-yellow-600'
                        : 'bg-gradient-to-r from-blue-500 to-blue-600'
                  }`}
                  style={{ width: `${violation.percentage}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* CARRIER SAFETY RATINGS TABLE */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 overflow-hidden">
        <div className="p-6 border-b border-white/10">
          <h2 className="text-xl font-bold">Carrier Safety Ratings</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-white/10 bg-white/5">
                <th className="px-6 py-4 text-left text-sm font-semibold">Carrier</th>
                <th className="px-6 py-4 text-center text-sm font-semibold">Rating</th>
                <th className="px-6 py-4 text-center text-sm font-semibold">Score</th>
                <th className="px-6 py-4 text-center text-sm font-semibold">Violations</th>
                <th className="px-6 py-4 text-center text-sm font-semibold">Complaints</th>
                <th className="px-6 py-4 text-right text-sm font-semibold">Last Inspection</th>
              </tr>
            </thead>
            <tbody>
              {carrierSafetyRatings.map((carrier) => {
                const colors = getSafetyColor(carrier.rating)
                return (
                  <tr key={carrier.id} className="border-b border-white/10 hover:bg-white/5 transition-colors">
                    <td className="px-6 py-4 font-semibold text-white">{carrier.name}</td>
                    <td className="px-6 py-4 text-center">
                      <span className={`px-3 py-1 ${colors.bg} ${colors.border} rounded-full ${colors.text} text-xs font-semibold border`}>
                        {carrier.rating}
                      </span>
                    </td>
                    <td className={`px-6 py-4 text-center font-bold ${colors.text}`}>{carrier.score.toFixed(1)}</td>
                    <td className={`px-6 py-4 text-center font-bold ${carrier.violations > 0 ? 'text-red-400' : 'text-green-400'}`}>
                      {carrier.violations}
                    </td>
                    <td className={`px-6 py-4 text-center font-bold ${carrier.complaints > 0 ? 'text-yellow-400' : 'text-green-400'}`}>
                      {carrier.complaints}
                    </td>
                    <td className="px-6 py-4 text-right text-gray-400">{new Date(carrier.lastInspection).toLocaleDateString()}</td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* COMPLIANCE REQUIREMENTS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Compliance Requirements</h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-3">
            <h3 className="font-semibold text-white">Documentation</h3>
            {['Driver CDL Validation', 'MVR Reports', 'Pre-Hire Screening', 'Annual Reviews'].map((doc, index) => (
              <div key={index} className="flex items-center gap-3 p-3 bg-white/5 rounded-lg border border-white/10">
                <span className="text-green-400">✓</span>
                <span className="text-gray-300">{doc}</span>
              </div>
            ))}
          </div>

          <div className="space-y-3">
            <h3 className="font-semibold text-white">Training & Certification</h3>
            {['HAZMAT Training', 'Safety Training', 'Vehicle Inspection', 'Defensive Driving'].map((training, index) => (
              <div key={index} className="flex items-center gap-3 p-3 bg-white/5 rounded-lg border border-white/10">
                <span className="text-green-400">✓</span>
                <span className="text-gray-300">{training}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* RECOMMENDED ACTIONS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Recommended Actions</h2>

        <div className="space-y-3">
          <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-4 flex items-start gap-4">
            <span className="text-2xl">⚠️</span>
            <div>
              <p className="font-semibold text-white">Review Unsatisfactory Carrier</p>
              <p className="text-sm text-gray-400 mt-1">Southern Transport has multiple violations. Consider suspension until safety improvements are made.</p>
            </div>
          </div>

          <div className="bg-yellow-500/10 border border-yellow-500/30 rounded-lg p-4 flex items-start gap-4">
            <span className="text-2xl">📋</span>
            <div>
              <p className="font-semibold text-white">Schedule Inspections for Conditional Carriers</p>
              <p className="text-sm text-gray-400 mt-1">36 carriers have conditional ratings. Schedule full safety audits within 60 days.</p>
            </div>
          </div>

          <div className="bg-blue-500/10 border border-blue-500/30 rounded-lg p-4 flex items-start gap-4">
            <span className="text-2xl">🎓</span>
            <div>
              <p className="font-semibold text-white">Implement Safety Training Program</p>
              <p className="text-sm text-gray-400 mt-1">Provide training to address top violations (Speeding, Vehicle Maintenance, Hours of Service).</p>
            </div>
          </div>
        </div>
      </div>

      {/* INFO CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-cyan-500/10 border border-cyan-500/30 rounded-xl p-6">
          <p className="text-sm text-cyan-400">
            <strong>🛡️ FMCSA Compliance:</strong> Regular safety audits and maintenance of safety records are required by federal regulation. Maintain documentation for audit readiness.
          </p>
        </div>
        <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
          <p className="text-sm text-blue-400">
            <strong>📊 Insight:</strong> Investing in carrier safety training can reduce violations, improve delivery performance, and reduce liability exposure.
          </p>
        </div>
      </div>
    </div>
  )
}

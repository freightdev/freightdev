'use client'

import React from 'react'
import Link from 'next/link'

export default function ReportsHubPage() {
  const reportTypes = [
    {
      id: 'revenue',
      title: 'Revenue Report',
      description: 'Detailed revenue analysis, trends, and commission breakdown',
      icon: '💰',
      href: '/dashboard/reports/revenue',
      color: 'from-green-500/20 to-green-600/20',
      borderColor: 'border-green-500/30',
    },
    {
      id: 'loads',
      title: 'Load Report',
      description: 'Load volume, distribution, and delivery performance metrics',
      icon: '📦',
      href: '/dashboard/reports/loads',
      color: 'from-blue-500/20 to-blue-600/20',
      borderColor: 'border-blue-500/30',
    },
    {
      id: 'carriers',
      title: 'Carrier Report',
      description: 'Carrier performance, ratings, and reliability metrics',
      icon: '🚚',
      href: '/dashboard/reports/carriers',
      color: 'from-purple-500/20 to-purple-600/20',
      borderColor: 'border-purple-500/30',
    },
    {
      id: 'commission',
      title: 'Commission Report',
      description: 'Commission payments, rates, and dispatcher earnings',
      icon: '💳',
      href: '/dashboard/reports/commission',
      color: 'from-amber-500/20 to-amber-600/20',
      borderColor: 'border-amber-500/30',
    },
    {
      id: 'insurance',
      title: 'Insurance Compliance',
      description: 'Insurance verification status and compliance tracking',
      icon: '📋',
      href: '/dashboard/reports/insurance',
      color: 'from-red-500/20 to-red-600/20',
      borderColor: 'border-red-500/30',
    },
    {
      id: 'safety',
      title: 'Safety & Compliance',
      description: 'Safety ratings, compliance records, and certifications',
      icon: '🛡️',
      href: '/dashboard/reports/safety',
      color: 'from-cyan-500/20 to-cyan-600/20',
      borderColor: 'border-cyan-500/30',
    },
  ]

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div>
        <h1 className="text-3xl font-bold">Reports & Analytics</h1>
        <p className="text-gray-400 mt-2">Generate and download detailed business reports</p>
      </div>

      {/* REPORT TYPES */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {reportTypes.map((report) => (
          <Link
            key={report.id}
            href={report.href}
            className={`bg-gradient-to-br ${report.color} rounded-xl border ${report.borderColor} p-6 hover:shadow-lg hover:shadow-current/20 transition-all group`}
          >
            <div className="space-y-4">
              <div className="flex items-start justify-between">
                <div>
                  <div className="text-4xl mb-3">{report.icon}</div>
                  <h3 className="text-xl font-bold group-hover:text-white transition-colors">{report.title}</h3>
                </div>
                <span className="text-2xl group-hover:translate-x-1 transition-transform">→</span>
              </div>
              <p className="text-sm text-gray-400">{report.description}</p>
            </div>
          </Link>
        ))}
      </div>

      {/* SCHEDULED REPORTS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Scheduled Reports</h2>
        <p className="text-gray-400 text-sm">Set up automatic report generation and email delivery</p>

        <div className="space-y-3">
          <div className="flex justify-between items-center p-4 bg-white/5 rounded-lg border border-white/10">
            <div>
              <p className="font-semibold">Weekly Revenue Report</p>
              <p className="text-sm text-gray-400">Every Monday at 8:00 AM</p>
            </div>
            <button className="px-3 py-1 text-xs bg-white/10 border border-white/20 rounded-lg hover:bg-white/20 transition-colors">
              Edit
            </button>
          </div>

          <div className="flex justify-between items-center p-4 bg-white/5 rounded-lg border border-white/10">
            <div>
              <p className="font-semibold">Monthly Carrier Report</p>
              <p className="text-sm text-gray-400">First day of month at 9:00 AM</p>
            </div>
            <button className="px-3 py-1 text-xs bg-white/10 border border-white/20 rounded-lg hover:bg-white/20 transition-colors">
              Edit
            </button>
          </div>
        </div>

        <Link
          href="/dashboard/reports/schedule"
          className="inline-block px-4 py-2 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white text-sm font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          + Schedule New Report
        </Link>
      </div>

      {/* RECENT REPORTS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Recent Reports</h2>

        <div className="space-y-3">
          <div className="flex justify-between items-center p-4 bg-white/5 rounded-lg border border-white/10">
            <div>
              <p className="font-semibold">Revenue-2024-11-20</p>
              <p className="text-sm text-gray-400">Generated 2 hours ago • 2.4 MB</p>
            </div>
            <button className="text-[#d946ef] hover:text-[#d946ef]/80 text-sm font-semibold">
              Download
            </button>
          </div>

          <div className="flex justify-between items-center p-4 bg-white/5 rounded-lg border border-white/10">
            <div>
              <p className="font-semibold">Carriers-2024-11-19</p>
              <p className="text-sm text-gray-400">Generated 1 day ago • 1.8 MB</p>
            </div>
            <button className="text-[#d946ef] hover:text-[#d946ef]/80 text-sm font-semibold">
              Download
            </button>
          </div>

          <div className="flex justify-between items-center p-4 bg-white/5 rounded-lg border border-white/10">
            <div>
              <p className="font-semibold">Loads-2024-11-18</p>
              <p className="text-sm text-gray-400">Generated 2 days ago • 1.6 MB</p>
            </div>
            <button className="text-[#d946ef] hover:text-[#d946ef]/80 text-sm font-semibold">
              Download
            </button>
          </div>
        </div>
      </div>

      {/* INFO CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
          <p className="text-sm text-blue-400">
            <strong>📊 Tip:</strong> Reports are generated on-demand and can be exported as PDF or Excel. Schedule recurring reports for automatic delivery to your email.
          </p>
        </div>
        <div className="bg-green-500/10 border border-green-500/30 rounded-xl p-6">
          <p className="text-sm text-green-400">
            <strong>✅ Pro:</strong> Use date filters to customize reports for specific periods or drill down into specific carriers or dispatchers.
          </p>
        </div>
      </div>
    </div>
  )
}

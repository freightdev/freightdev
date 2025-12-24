'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useScheduledReports } from '@/lib/hooks/useAnalytics'

export default function ScheduleReportPage() {
  const [showNewScheduleForm, setShowNewScheduleForm] = useState(false)
  const [selectedReport, setSelectedReport] = useState('revenue')
  const [selectedFrequency, setSelectedFrequency] = useState('weekly')
  const [selectedTime, setSelectedTime] = useState('08:00')
  const [recipientEmail, setRecipientEmail] = useState('')
  const [includeCharts, setIncludeCharts] = useState(true)
  const [loading, setLoading] = useState(false)
  const [formError, setFormError] = useState('')

  const { scheduleReport } = useScheduledReports()

  const reportTypes = [
    { id: 'revenue', name: 'Revenue Report', description: 'Revenue analysis and trends' },
    { id: 'loads', name: 'Load Report', description: 'Load volume and distribution' },
    { id: 'carriers', name: 'Carrier Report', description: 'Carrier performance metrics' },
    { id: 'commission', name: 'Commission Report', description: 'Commission earnings' },
    { id: 'insurance', name: 'Insurance Compliance', description: 'Insurance verification' },
    { id: 'safety', name: 'Safety & Compliance', description: 'Safety ratings and violations' },
  ]

  const frequencies = [
    { id: 'daily', label: 'Daily', description: 'Every day at selected time' },
    { id: 'weekly', label: 'Weekly', description: 'Every Monday at selected time' },
    { id: 'biweekly', label: 'Bi-weekly', description: 'Every 2 weeks' },
    { id: 'monthly', label: 'Monthly', description: 'First day of month' },
  ]

  const scheduledReports = [
    {
      id: 1,
      name: 'Weekly Revenue Report',
      report: 'Revenue Report',
      frequency: 'weekly',
      time: '08:00',
      recipient: 'admin@company.com',
      lastSent: '2024-11-25',
      nextSend: '2024-12-02',
      status: 'active',
    },
    {
      id: 2,
      name: 'Monthly Carrier Performance',
      report: 'Carrier Report',
      frequency: 'monthly',
      time: '09:00',
      recipient: 'operations@company.com',
      lastSent: '2024-11-01',
      nextSend: '2024-12-01',
      status: 'active',
    },
    {
      id: 3,
      name: 'Daily Load Summary',
      report: 'Load Report',
      frequency: 'daily',
      time: '17:00',
      recipient: 'dispatcher@company.com',
      lastSent: '2024-11-25',
      nextSend: '2024-11-26',
      status: 'active',
    },
  ]

  const handleScheduleReport = async (e: React.FormEvent) => {
    e.preventDefault()
    setFormError('')

    if (!recipientEmail) {
      setFormError('Please enter a recipient email address')
      return
    }

    setLoading(true)
    try {
      await scheduleReport(selectedReport, selectedFrequency as 'daily' | 'weekly' | 'monthly', recipientEmail, {
        startDate: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0],
      })

      // Reset form
      setRecipientEmail('')
      setSelectedReport('revenue')
      setSelectedFrequency('weekly')
      setShowNewScheduleForm(false)

      // Show success message
      alert('Report scheduled successfully!')
    } catch (error) {
      setFormError('Failed to schedule report. Please try again.')
      console.error('Error scheduling report:', error)
    } finally {
      setLoading(false)
    }
  }

  const getFrequencyLabel = (frequency: string) => {
    const freq = frequencies.find((f) => f.id === frequency)
    return freq ? freq.label : frequency
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
            <span className="text-white">Schedule Reports</span>
          </div>
          <h1 className="text-3xl font-bold">Schedule Reports</h1>
          <p className="text-gray-400 mt-2">Set up automatic report generation and email delivery</p>
        </div>
        <button
          onClick={() => setShowNewScheduleForm(!showNewScheduleForm)}
          className="px-4 py-2 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white text-sm font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          + Schedule New Report
        </button>
      </div>

      {/* NEW SCHEDULE FORM */}
      {showNewScheduleForm && (
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Create New Scheduled Report</h2>

          <form onSubmit={handleScheduleReport} className="space-y-4">
            {/* Report Type */}
            <div>
              <label className="block text-sm font-medium mb-3">Select Report Type</label>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                {reportTypes.map((report) => (
                  <button
                    key={report.id}
                    type="button"
                    onClick={() => setSelectedReport(report.id)}
                    className={`p-3 rounded-lg border transition-all text-left ${
                      selectedReport === report.id
                        ? 'bg-purple-500/20 border-purple-500/50'
                        : 'bg-white/5 border-white/10 hover:border-white/20'
                    }`}
                  >
                    <p className={`font-semibold ${selectedReport === report.id ? 'text-purple-400' : 'text-white'}`}>
                      {report.name}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">{report.description}</p>
                  </button>
                ))}
              </div>
            </div>

            {/* Frequency */}
            <div>
              <label className="block text-sm font-medium mb-3">Report Frequency</label>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                {frequencies.map((freq) => (
                  <button
                    key={freq.id}
                    type="button"
                    onClick={() => setSelectedFrequency(freq.id)}
                    className={`p-3 rounded-lg border transition-all text-left ${
                      selectedFrequency === freq.id
                        ? 'bg-blue-500/20 border-blue-500/50'
                        : 'bg-white/5 border-white/10 hover:border-white/20'
                    }`}
                  >
                    <p className={`font-semibold ${selectedFrequency === freq.id ? 'text-blue-400' : 'text-white'}`}>
                      {freq.label}
                    </p>
                    <p className="text-xs text-gray-400 mt-1">{freq.description}</p>
                  </button>
                ))}
              </div>
            </div>

            {/* Recipient Email and Time */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-2">Recipient Email</label>
                <input
                  type="email"
                  value={recipientEmail}
                  onChange={(e) => setRecipientEmail(e.target.value)}
                  placeholder="example@company.com"
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white placeholder-gray-500 focus:outline-none focus:border-purple-500/50 transition-colors"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Delivery Time</label>
                <input
                  type="time"
                  value={selectedTime}
                  onChange={(e) => setSelectedTime(e.target.value)}
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-purple-500/50 transition-colors"
                />
              </div>
            </div>

            {/* Options */}
            <div>
              <label className="block text-sm font-medium mb-3">Report Options</label>
              <div className="flex items-center gap-3 p-3 bg-white/5 rounded-lg border border-white/10">
                <input
                  type="checkbox"
                  id="includeCharts"
                  checked={includeCharts}
                  onChange={(e) => setIncludeCharts(e.target.checked)}
                  className="w-4 h-4 rounded"
                />
                <label htmlFor="includeCharts" className="text-sm text-white cursor-pointer flex-1">
                  Include charts and visualizations
                </label>
              </div>
            </div>

            {/* Error Message */}
            {formError && (
              <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-4">
                <p className="text-red-400 text-sm">{formError}</p>
              </div>
            )}

            {/* Submit Buttons */}
            <div className="flex gap-3 pt-4">
              <button
                type="submit"
                disabled={loading}
                className="flex-1 px-4 py-2 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white text-sm font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all disabled:opacity-50"
              >
                {loading ? 'Scheduling...' : 'Schedule Report'}
              </button>
              <button
                type="button"
                onClick={() => setShowNewScheduleForm(false)}
                className="flex-1 px-4 py-2 bg-white/10 border border-white/20 rounded-lg text-white text-sm font-semibold hover:bg-white/20 transition-colors"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      {/* INFO CARD */}
      <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
        <p className="text-sm text-blue-400">
          <strong>ℹ️ Info:</strong> Scheduled reports will be automatically generated and delivered to your specified email address at the selected time. You can create multiple schedules for different teams and use cases.
        </p>
      </div>

      {/* ACTIVE SCHEDULES */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Active Scheduled Reports ({scheduledReports.length})</h2>

        <div className="space-y-4">
          {scheduledReports.map((schedule) => (
            <div key={schedule.id} className="bg-white/5 rounded-lg p-4 border border-white/10 hover:border-white/20 transition-colors">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <h3 className="font-semibold text-white">{schedule.name}</h3>
                  <p className="text-sm text-gray-400 mt-1">
                    {schedule.report} • {getFrequencyLabel(schedule.frequency)} at {schedule.time}
                  </p>
                </div>
                <span className="px-3 py-1 bg-green-500/20 border border-green-500/30 rounded-full text-green-400 text-xs font-semibold">
                  Active
                </span>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-4 gap-3 mb-3">
                <div className="bg-white/5 rounded p-2">
                  <p className="text-xs text-gray-400">Recipient</p>
                  <p className="text-sm font-semibold text-white mt-1">{schedule.recipient}</p>
                </div>
                <div className="bg-white/5 rounded p-2">
                  <p className="text-xs text-gray-400">Last Sent</p>
                  <p className="text-sm font-semibold text-white mt-1">{new Date(schedule.lastSent).toLocaleDateString()}</p>
                </div>
                <div className="bg-white/5 rounded p-2">
                  <p className="text-xs text-gray-400">Next Send</p>
                  <p className="text-sm font-semibold text-white mt-1">{new Date(schedule.nextSend).toLocaleDateString()}</p>
                </div>
                <div className="flex gap-2">
                  <button className="flex-1 px-3 py-2 bg-white/10 border border-white/20 rounded text-white hover:bg-white/20 transition-colors text-xs font-semibold">
                    Edit
                  </button>
                  <button className="flex-1 px-3 py-2 bg-red-500/20 border border-red-500/30 rounded text-red-400 hover:bg-red-500/30 transition-colors text-xs font-semibold">
                    Delete
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* DELIVERY HISTORY */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
        <h2 className="text-xl font-bold">Recent Deliveries</h2>

        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-white/10">
                <th className="px-4 py-3 text-left font-semibold text-gray-400">Report</th>
                <th className="px-4 py-3 text-left font-semibold text-gray-400">Recipient</th>
                <th className="px-4 py-3 text-center font-semibold text-gray-400">Sent</th>
                <th className="px-4 py-3 text-center font-semibold text-gray-400">Size</th>
                <th className="px-4 py-3 text-center font-semibold text-gray-400">Status</th>
              </tr>
            </thead>
            <tbody>
              {[
                {
                  report: 'Weekly Revenue Report',
                  recipient: 'admin@company.com',
                  sent: '2024-11-25T08:15:00',
                  size: '2.4 MB',
                  status: 'delivered',
                },
                {
                  report: 'Daily Load Summary',
                  recipient: 'dispatcher@company.com',
                  sent: '2024-11-25T17:02:00',
                  size: '1.1 MB',
                  status: 'delivered',
                },
                {
                  report: 'Monthly Carrier Performance',
                  recipient: 'operations@company.com',
                  sent: '2024-11-01T09:30:00',
                  size: '3.8 MB',
                  status: 'delivered',
                },
                {
                  report: 'Weekly Revenue Report',
                  recipient: 'admin@company.com',
                  sent: '2024-11-18T08:12:00',
                  size: '2.3 MB',
                  status: 'delivered',
                },
              ].map((delivery, index) => (
                <tr key={index} className="border-b border-white/5 hover:bg-white/5 transition-colors">
                  <td className="px-4 py-3 font-semibold text-white">{delivery.report}</td>
                  <td className="px-4 py-3 text-gray-400">{delivery.recipient}</td>
                  <td className="px-4 py-3 text-center text-gray-400">
                    {new Date(delivery.sent).toLocaleDateString()} {new Date(delivery.sent).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </td>
                  <td className="px-4 py-3 text-center text-gray-400">{delivery.size}</td>
                  <td className="px-4 py-3 text-center">
                    <span className="px-3 py-1 bg-green-500/20 border border-green-500/30 rounded-full text-green-400 text-xs font-semibold">
                      ✓ Delivered
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* TIPS */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-green-500/10 border border-green-500/30 rounded-xl p-6">
          <p className="text-sm text-green-400">
            <strong>✅ Tip:</strong> Schedule reports for early morning or end-of-day to ensure your team reviews them at the right time.
          </p>
        </div>
        <div className="bg-purple-500/10 border border-purple-500/30 rounded-xl p-6">
          <p className="text-sm text-purple-400">
            <strong>💡 Insight:</strong> Create multiple schedules with different frequencies to serve different team needs and decision cycles.
          </p>
        </div>
        <div className="bg-blue-500/10 border border-blue-500/30 rounded-xl p-6">
          <p className="text-sm text-blue-400">
            <strong>📊 Note:</strong> All scheduled reports include charts and visualizations to help with quick analysis and presentation.
          </p>
        </div>
      </div>
    </div>
  )
}

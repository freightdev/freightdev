'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function LoadFinderAgreementPage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    companyName: '',
    finderName: '',
    finderEmail: '',
    finderPhone: '',
    effectiveDate: '',
    commissionRate: '12%',
    paymentTerms: 'Weekly',
    loadSources: 'DAT, Broker.com, Load boards, Direct shippers',
    responsibilities: 'Load identification, broker negotiation, and load delivery coordination',
    terminationNotice: '14 days',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    addToast('Load Finder agreement saved successfully', 'success')
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <Link href="/dashboard/forms" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block">
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">Load Finder Agreement</h1>
          <p className="text-gray-400 mt-2">12% commission - Find and source loads</p>
        </div>
        <button
          onClick={() => addToast('Downloading Load Finder Agreement...', 'info')}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          📥 Download PDF
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* SECTION 1: PARTY INFORMATION */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Party Information</h2>
          <div className="grid grid-cols-2 gap-4">
            <input
              type="text"
              name="companyName"
              value={formData.companyName}
              onChange={handleChange}
              placeholder="Company name"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="date"
              name="effectiveDate"
              value={formData.effectiveDate}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        {/* SECTION 2: LOAD FINDER INFORMATION */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Load Finder Information</h2>
          <input
            type="text"
            name="finderName"
            value={formData.finderName}
            onChange={handleChange}
            placeholder="Load finder name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="email"
            name="finderEmail"
            value={formData.finderEmail}
            onChange={handleChange}
            placeholder="Email address"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="tel"
            name="finderPhone"
            value={formData.finderPhone}
            onChange={handleChange}
            placeholder="Phone number"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        {/* SECTION 3: AGREEMENT TERMS */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Commission & Payment</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Commission Rate</label>
              <select
                name="commissionRate"
                value={formData.commissionRate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              >
                <option>8%</option>
                <option>10%</option>
                <option>12%</option>
                <option>15%</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Payment Terms</label>
              <select
                name="paymentTerms"
                value={formData.paymentTerms}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              >
                <option>Weekly</option>
                <option>Bi-weekly</option>
                <option>Monthly</option>
              </select>
            </div>
          </div>
        </div>

        {/* SECTION 4: LOAD SOURCES */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Load Sources & Responsibilities</h2>
          <div>
            <label className="block text-sm font-medium mb-2">Approved Load Sources</label>
            <textarea
              name="loadSources"
              value={formData.loadSources}
              onChange={handleChange}
              rows={3}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Responsibilities</label>
            <textarea
              name="responsibilities"
              value={formData.responsibilities}
              onChange={handleChange}
              rows={3}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        <div className="flex gap-4">
          <button
            type="submit"
            className="flex-1 px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
          >
            Save Agreement
          </button>
          <Link
            href="/dashboard/forms"
            className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center"
          >
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}

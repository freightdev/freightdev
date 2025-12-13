'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function PaperworkOnlyAgreementPage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    companyName: '',
    vendorName: '',
    vendorEmail: '',
    vendorPhone: '',
    effectiveDate: '',
    commissionRate: '3%',
    paymentTerms: 'Monthly',
    services: 'Document preparation, filing, and administrative support only',
    responsibilities: 'Paperwork management, record keeping, and filing coordination',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    addToast('Paperwork Only agreement saved successfully', 'success')
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <Link href="/dashboard/forms" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block">
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">Paperwork Only Agreement</h1>
          <p className="text-gray-400 mt-2">3% commission - Administrative support only</p>
        </div>
        <button
          onClick={() => addToast('Downloading Paperwork Only Agreement...', 'info')}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          📥 Download PDF
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Agreement Information</h2>
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
            <input
              type="text"
              name="vendorName"
              value={formData.vendorName}
              onChange={handleChange}
              placeholder="Vendor/contractor name"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="email"
              name="vendorEmail"
              value={formData.vendorEmail}
              onChange={handleChange}
              placeholder="Email address"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="tel"
              name="vendorPhone"
              value={formData.vendorPhone}
              onChange={handleChange}
              placeholder="Phone number"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <select
              name="paymentTerms"
              value={formData.paymentTerms}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>Monthly</option>
              <option>Bi-weekly</option>
              <option>Quarterly</option>
            </select>
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Services & Responsibilities</h2>
          <textarea
            name="services"
            value={formData.services}
            onChange={handleChange}
            placeholder="List services to be provided"
            rows={3}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
          <textarea
            name="responsibilities"
            value={formData.responsibilities}
            onChange={handleChange}
            placeholder="Define responsibilities"
            rows={3}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="flex gap-4">
          <button
            type="submit"
            className="flex-1 px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
          >
            Save Agreement
          </button>
          <Link href="/dashboard/forms" className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}

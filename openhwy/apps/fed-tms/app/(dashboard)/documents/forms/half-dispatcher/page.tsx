'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function HalfDispatcherAgreementPage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    companyName: '',
    dispatcherName: '',
    dispatcherEmail: '',
    dispatcherPhone: '',
    effectiveDate: '',
    commissionRate: '4%',
    paymentTerms: 'Weekly',
    authority: 'Load selection and customer communication only. Rate negotiation handled by company.',
    responsibilities: 'Load management, driver communication, and delivery coordination. Company handles rate negotiations.',
    terminationNotice: '30 days',
    nonCompete: '1 year',
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
    addToast('Half Dispatcher agreement saved successfully', 'success')
  }

  const handleDownload = () => {
    addToast('Downloading Half Dispatcher Agreement...', 'info')
  }

  const handleSendForSignature = () => {
    addToast('Sending agreement for e-signature...', 'info')
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex justify-between items-center">
        <div>
          <Link
            href="/dashboard/forms"
            className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block"
          >
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">Half Dispatcher Agreement</h1>
          <p className="text-gray-400 mt-2">4% service fee - Limited dispatch authority</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={handleDownload}
            className="px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all"
          >
            📥 Download PDF
          </button>
          <button
            onClick={handleSendForSignature}
            className="px-6 py-3 bg-gradient-to-r from-green-600 to-green-500 rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-green-600/40 transition-all"
          >
            ✍️ Send for Signature
          </button>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* MAIN FORM */}
        <div className="col-span-2 space-y-6">
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* SECTION 1: PARTY INFORMATION */}
            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
              <h2 className="text-xl font-bold">Party Information</h2>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-2">Company Name</label>
                  <input
                    type="text"
                    name="companyName"
                    value={formData.companyName}
                    onChange={handleChange}
                    placeholder="Fast & Easy Dispatching LLC"
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-2">Effective Date</label>
                  <input
                    type="date"
                    name="effectiveDate"
                    value={formData.effectiveDate}
                    onChange={handleChange}
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                  />
                </div>
              </div>
            </div>

            {/* SECTION 2: DISPATCHER INFORMATION */}
            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
              <h2 className="text-xl font-bold">Dispatcher Information</h2>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-2">Dispatcher Name</label>
                  <input
                    type="text"
                    name="dispatcherName"
                    value={formData.dispatcherName}
                    onChange={handleChange}
                    placeholder="Full name"
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-2">Phone Number</label>
                  <input
                    type="tel"
                    name="dispatcherPhone"
                    value={formData.dispatcherPhone}
                    onChange={handleChange}
                    placeholder="(555) 123-4567"
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                  />
                </div>
                <div className="col-span-2">
                  <label className="block text-sm font-medium mb-2">Email Address</label>
                  <input
                    type="email"
                    name="dispatcherEmail"
                    value={formData.dispatcherEmail}
                    onChange={handleChange}
                    placeholder="dispatcher@example.com"
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                  />
                </div>
              </div>
            </div>

            {/* SECTION 3: AGREEMENT TERMS */}
            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
              <h2 className="text-xl font-bold">Agreement Terms</h2>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-2">Commission Rate</label>
                  <select
                    name="commissionRate"
                    value={formData.commissionRate}
                    onChange={handleChange}
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                  >
                    <option>2%</option>
                    <option>4%</option>
                    <option>6%</option>
                    <option>8%</option>
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

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium mb-2">Termination Notice (Days)</label>
                  <select
                    name="terminationNotice"
                    value={formData.terminationNotice}
                    onChange={handleChange}
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                  >
                    <option>7 days</option>
                    <option>14 days</option>
                    <option>30 days</option>
                    <option>60 days</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium mb-2">Non-Compete Period</label>
                  <select
                    name="nonCompete"
                    value={formData.nonCompete}
                    onChange={handleChange}
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                  >
                    <option>6 months</option>
                    <option>1 year</option>
                    <option>2 years</option>
                  </select>
                </div>
              </div>
            </div>

            {/* SECTION 4: AUTHORITY & RESPONSIBILITIES */}
            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
              <h2 className="text-xl font-bold">Authority & Responsibilities</h2>

              <div>
                <label className="block text-sm font-medium mb-2">Dispatcher Authority</label>
                <textarea
                  name="authority"
                  value={formData.authority}
                  onChange={handleChange}
                  rows={3}
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                />
              </div>

              <div>
                <label className="block text-sm font-medium mb-2">Dispatcher Responsibilities</label>
                <textarea
                  name="responsibilities"
                  value={formData.responsibilities}
                  onChange={handleChange}
                  rows={3}
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                />
              </div>
            </div>

            {/* SUBMIT BUTTONS */}
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

        {/* SIDEBAR - TEMPLATE INFO */}
        <div className="space-y-6">
          {/* AGREEMENT DETAILS */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h3 className="font-bold">Agreement Details</h3>
            <div className="space-y-3 text-sm">
              <div>
                <p className="text-gray-400">Type</p>
                <p className="font-semibold">Half Dispatcher Agreement</p>
              </div>
              <div>
                <p className="text-gray-400">Commission</p>
                <p className="font-semibold text-blue-400">4%</p>
              </div>
              <div>
                <p className="text-gray-400">Authority Level</p>
                <p className="font-semibold">Limited</p>
              </div>
              <div>
                <p className="text-gray-400">Services Included</p>
                <ul className="text-sm text-gray-300 space-y-1 mt-2">
                  <li>✓ Load selection</li>
                  <li>✓ Customer contact</li>
                  <li>✓ Driver management</li>
                  <li>✗ Rate negotiation (Company handles)</li>
                </ul>
              </div>
            </div>
          </div>

          {/* QUICK ACTIONS */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-3">
            <h3 className="font-bold">Quick Actions</h3>
            <button className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-sm">
              📋 View Template
            </button>
            <button className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-sm">
              📧 Send Example
            </button>
            <button className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-sm">
              ⚙️ Customize Template
            </button>
          </div>

          {/* LEGAL NOTE */}
          <div className="bg-yellow-600/20 border border-yellow-600/50 rounded-xl p-4">
            <p className="text-xs text-yellow-400">
              <strong>⚠️ Legal Disclaimer:</strong> This form is a template. Consult with legal counsel before use to ensure compliance with your jurisdiction.
            </p>
          </div>
        </div>
      </div>
    </div>
  )
}

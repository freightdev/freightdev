'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function CertificateInsurancePage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    carrierName: '',
    insuranceCompany: '',
    policyNumber: '',
    liabilityLimit: '$100,000',
    cargoLimit: '$50,000',
    bodilyInjuryLimit: '$100,000',
    propertyDamageLimit: '$100,000',
    effectiveDate: '',
    expirationDate: '',
    brokerName: '',
    brokerPhone: '',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    addToast('Certificate of Insurance saved successfully', 'success')
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <Link href="/dashboard/forms" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block">
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">Certificate of Insurance (COI)</h1>
          <p className="text-gray-400 mt-2">Proof of insurance coverage for carriers</p>
        </div>
        <button
          onClick={() => addToast('Downloading COI...', 'info')}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          📥 Download PDF
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Carrier Information</h2>
          <input
            type="text"
            name="carrierName"
            value={formData.carrierName}
            onChange={handleChange}
            placeholder="Carrier/Motor Carrier name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Insurance Company Information</h2>
          <input
            type="text"
            name="insuranceCompany"
            value={formData.insuranceCompany}
            onChange={handleChange}
            placeholder="Insurance company name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="policyNumber"
            value={formData.policyNumber}
            onChange={handleChange}
            placeholder="Policy number"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Coverage Limits</h2>
          <div className="grid grid-cols-2 gap-4">
            <select
              name="liabilityLimit"
              value={formData.liabilityLimit}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>$100,000</option>
              <option>$250,000</option>
              <option>$500,000</option>
              <option>$1,000,000</option>
            </select>
            <select
              name="cargoLimit"
              value={formData.cargoLimit}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>$50,000</option>
              <option>$100,000</option>
              <option>$250,000</option>
              <option>$500,000</option>
            </select>
            <select
              name="bodilyInjuryLimit"
              value={formData.bodilyInjuryLimit}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>$100,000</option>
              <option>$250,000</option>
              <option>$500,000</option>
              <option>$1,000,000</option>
            </select>
            <select
              name="propertyDamageLimit"
              value={formData.propertyDamageLimit}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>$100,000</option>
              <option>$250,000</option>
              <option>$500,000</option>
              <option>$1,000,000</option>
            </select>
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Policy Dates</h2>
          <div className="grid grid-cols-2 gap-4">
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
            <div>
              <label className="block text-sm font-medium mb-2">Expiration Date</label>
              <input
                type="date"
                name="expirationDate"
                value={formData.expirationDate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Insurance Broker Contact</h2>
          <input
            type="text"
            name="brokerName"
            value={formData.brokerName}
            onChange={handleChange}
            placeholder="Broker/Agent name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="tel"
            name="brokerPhone"
            value={formData.brokerPhone}
            onChange={handleChange}
            placeholder="Broker contact phone"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="flex gap-4">
          <button
            type="submit"
            className="flex-1 px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
          >
            Save Certificate
          </button>
          <Link href="/dashboard/forms" className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}

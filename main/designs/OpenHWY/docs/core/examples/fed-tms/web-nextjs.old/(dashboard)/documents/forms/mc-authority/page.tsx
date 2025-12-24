'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function MCAuthorityPage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    carrierName: '',
    mcNumber: '',
    dotNumber: '',
    businessAddress: '',
    businessCity: '',
    businessState: '',
    businessZip: '',
    businessPhone: '',
    mailingAddress: '',
    mailingCity: '',
    mailingState: '',
    mailingZip: '',
    principalName: '',
    principalTitle: '',
    principalPhone: '',
    operatingType: 'Common Carrier',
    classificationCode: '',
    authorityIssueDate: '',
    authorityExpirationDate: '',
    vehicleDescription: '',
    maxWeight: '',
    insuranceCarrier: '',
    policyNumber: '',
    insuranceType: 'General Public Liability',
    minInsuranceAmount: '$1,000,000',
    filingStatus: 'Current',
    outOfService: 'No',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    addToast('MC Authority Certificate information saved successfully', 'success')
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <Link href="/dashboard/forms" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block">
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">MC Authority Certificate</h1>
          <p className="text-gray-400 mt-2">Motor Carrier operating authority documentation</p>
        </div>
        <button
          onClick={() => addToast('Downloading MC Authority...', 'info')}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          📥 Download PDF
        </button>
      </div>

      <div className="bg-blue-600/20 border border-blue-600/50 rounded-xl p-4">
        <p className="text-sm text-blue-400">
          <strong>ℹ️ Required:</strong> MC Authority is required for all motor carriers engaged in interstate commerce. This information is based on FMCSA records.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Carrier Identification</h2>
          <input
            type="text"
            name="carrierName"
            value={formData.carrierName}
            onChange={handleChange}
            placeholder="Legal carrier name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-2 gap-4 mb-3">
            <input
              type="text"
              name="mcNumber"
              value={formData.mcNumber}
              onChange={handleChange}
              placeholder="MC Number"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="dotNumber"
              value={formData.dotNumber}
              onChange={handleChange}
              placeholder="DOT Number"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Principal Business Address</h2>
          <input
            type="text"
            name="businessAddress"
            value={formData.businessAddress}
            onChange={handleChange}
            placeholder="Street address"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-4 gap-4 mb-3">
            <input
              type="text"
              name="businessCity"
              value={formData.businessCity}
              onChange={handleChange}
              placeholder="City"
              className="col-span-2 bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="businessState"
              value={formData.businessState}
              onChange={handleChange}
              placeholder="State"
              className="bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="businessZip"
              value={formData.businessZip}
              onChange={handleChange}
              placeholder="ZIP"
              className="bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <input
            type="tel"
            name="businessPhone"
            value={formData.businessPhone}
            onChange={handleChange}
            placeholder="Phone number"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Mailing Address (if different)</h2>
          <input
            type="text"
            name="mailingAddress"
            value={formData.mailingAddress}
            onChange={handleChange}
            placeholder="Street address"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-4 gap-4">
            <input
              type="text"
              name="mailingCity"
              value={formData.mailingCity}
              onChange={handleChange}
              placeholder="City"
              className="col-span-2 bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="mailingState"
              value={formData.mailingState}
              onChange={handleChange}
              placeholder="State"
              className="bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="mailingZip"
              value={formData.mailingZip}
              onChange={handleChange}
              placeholder="ZIP"
              className="bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Principal Official</h2>
          <input
            type="text"
            name="principalName"
            value={formData.principalName}
            onChange={handleChange}
            placeholder="Full name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="principalTitle"
            value={formData.principalTitle}
            onChange={handleChange}
            placeholder="Title/Position"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="tel"
            name="principalPhone"
            value={formData.principalPhone}
            onChange={handleChange}
            placeholder="Phone number"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Operating Authority Details</h2>
          <select
            name="operatingType"
            value={formData.operatingType}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          >
            <option>Common Carrier</option>
            <option>Contract Carrier</option>
            <option>Exempt Carrier</option>
            <option>Private Carrier</option>
          </select>
          <input
            type="text"
            name="classificationCode"
            value={formData.classificationCode}
            onChange={handleChange}
            placeholder="Commodity Classification Code"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <textarea
            name="vehicleDescription"
            value={formData.vehicleDescription}
            onChange={handleChange}
            placeholder="Vehicle description and configuration"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="maxWeight"
            value={formData.maxWeight}
            onChange={handleChange}
            placeholder="Maximum weight (lbs)"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Authority Dates</h2>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Authority Issued Date</label>
              <input
                type="date"
                name="authorityIssueDate"
                value={formData.authorityIssueDate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Authority Expiration Date</label>
              <input
                type="date"
                name="authorityExpirationDate"
                value={formData.authorityExpirationDate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Insurance Verification</h2>
          <input
            type="text"
            name="insuranceCarrier"
            value={formData.insuranceCarrier}
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
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-2 gap-4">
            <select
              name="insuranceType"
              value={formData.insuranceType}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>General Public Liability</option>
              <option>Cargo</option>
              <option>Bobtail</option>
              <option>Physical Damage</option>
            </select>
            <select
              name="minInsuranceAmount"
              value={formData.minInsuranceAmount}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>$300,000</option>
              <option>$500,000</option>
              <option>$750,000</option>
              <option>$1,000,000</option>
              <option>$2,000,000</option>
            </select>
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Filing Status</h2>
          <div className="grid grid-cols-2 gap-4">
            <select
              name="filingStatus"
              value={formData.filingStatus}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>Current</option>
              <option>Expired</option>
              <option>Surrendered</option>
              <option>Revoked</option>
            </select>
            <select
              name="outOfService"
              value={formData.outOfService}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>No</option>
              <option>Yes</option>
            </select>
          </div>
        </div>

        <div className="flex gap-4">
          <button
            type="submit"
            className="flex-1 px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
          >
            Save MC Authority Certificate
          </button>
          <Link href="/dashboard/forms" className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}

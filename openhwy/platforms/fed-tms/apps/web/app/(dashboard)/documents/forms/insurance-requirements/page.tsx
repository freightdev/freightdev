'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function InsuranceRequirementsPage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    carrierName: '',
    mcNumber: '',
    contactPerson: '',
    contactPhone: '',
    contactEmail: '',
    generalLiability: 'Not Required',
    generalLiabilityAmount: '$1,000,000',
    generalLiabilityCarrier: '',
    generalLiabilityPolicy: '',
    cargo: 'Required',
    cargoAmount: '$100,000',
    cargoCarrier: '',
    cargoPolicy: '',
    bobtail: 'Not Required',
    bobtailAmount: '$750,000',
    bobtailCarrier: '',
    bobtailPolicy: '',
    physicalDamage: 'Not Required',
    physicalDamageAmount: '$500,000',
    physicalDamageCarrier: '',
    physicalDamagePolicy: '',
    workersComp: 'Not Required',
    workersCompAmount: '',
    workersCompCarrier: '',
    workersCompPolicy: '',
    additionalInsurance: '',
    endorsements: '',
    certRequired: 'Yes',
    holderName: '',
    renewalDate: '',
    auditDate: '',
    notes: '',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    addToast('Insurance Requirements saved successfully', 'success')
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <Link href="/dashboard/forms" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block">
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">Insurance Requirements Checklist</h1>
          <p className="text-gray-400 mt-2">Comprehensive insurance coverage verification</p>
        </div>
        <button
          onClick={() => addToast('Downloading Insurance Requirements...', 'info')}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          📥 Download PDF
        </button>
      </div>

      <div className="bg-yellow-600/20 border border-yellow-600/50 rounded-xl p-4">
        <p className="text-sm text-yellow-400">
          <strong>⚠️ Compliance:</strong> Proper insurance coverage is essential for interstate commerce. Verify all policies are current and meet minimum requirements.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Carrier Information</h2>
          <input
            type="text"
            name="carrierName"
            value={formData.carrierName}
            onChange={handleChange}
            placeholder="Carrier name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-3 gap-4 mb-3">
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
              name="contactPerson"
              value={formData.contactPerson}
              onChange={handleChange}
              placeholder="Contact person"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="email"
              name="contactEmail"
              value={formData.contactEmail}
              onChange={handleChange}
              placeholder="Email"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <input
            type="tel"
            name="contactPhone"
            value={formData.contactPhone}
            onChange={handleChange}
            placeholder="Phone number"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">General Liability Insurance</h2>
          <select
            name="generalLiability"
            value={formData.generalLiability}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          >
            <option>Not Required</option>
            <option>Required</option>
            <option>Not Applicable</option>
          </select>
          {formData.generalLiability === 'Required' && (
            <>
              <select
                name="generalLiabilityAmount"
                value={formData.generalLiabilityAmount}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
              >
                <option>$300,000</option>
                <option>$500,000</option>
                <option>$750,000</option>
                <option>$1,000,000</option>
                <option>$2,000,000</option>
              </select>
              <input
                type="text"
                name="generalLiabilityCarrier"
                value={formData.generalLiabilityCarrier}
                onChange={handleChange}
                placeholder="Insurance carrier name"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
              />
              <input
                type="text"
                name="generalLiabilityPolicy"
                value={formData.generalLiabilityPolicy}
                onChange={handleChange}
                placeholder="Policy number"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </>
          )}
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Cargo Insurance</h2>
          <select
            name="cargo"
            value={formData.cargo}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          >
            <option>Not Required</option>
            <option>Required</option>
            <option>Conditional</option>
          </select>
          {formData.cargo !== 'Not Required' && (
            <>
              <select
                name="cargoAmount"
                value={formData.cargoAmount}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
              >
                <option>$50,000</option>
                <option>$100,000</option>
                <option>$250,000</option>
                <option>$500,000</option>
                <option>$1,000,000</option>
              </select>
              <input
                type="text"
                name="cargoCarrier"
                value={formData.cargoCarrier}
                onChange={handleChange}
                placeholder="Insurance carrier name"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
              />
              <input
                type="text"
                name="cargoPolicy"
                value={formData.cargoPolicy}
                onChange={handleChange}
                placeholder="Policy number"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </>
          )}
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Bobtail Insurance</h2>
          <select
            name="bobtail"
            value={formData.bobtail}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          >
            <option>Not Required</option>
            <option>Required</option>
            <option>Recommended</option>
          </select>
          {formData.bobtail !== 'Not Required' && (
            <>
              <select
                name="bobtailAmount"
                value={formData.bobtailAmount}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
              >
                <option>$300,000</option>
                <option>$500,000</option>
                <option>$750,000</option>
                <option>$1,000,000</option>
              </select>
              <input
                type="text"
                name="bobtailCarrier"
                value={formData.bobtailCarrier}
                onChange={handleChange}
                placeholder="Insurance carrier name"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
              />
              <input
                type="text"
                name="bobtailPolicy"
                value={formData.bobtailPolicy}
                onChange={handleChange}
                placeholder="Policy number"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </>
          )}
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Physical Damage Insurance</h2>
          <select
            name="physicalDamage"
            value={formData.physicalDamage}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          >
            <option>Not Required</option>
            <option>Required</option>
            <option>Recommended</option>
          </select>
          {formData.physicalDamage !== 'Not Required' && (
            <>
              <select
                name="physicalDamageAmount"
                value={formData.physicalDamageAmount}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
              >
                <option>$250,000</option>
                <option>$500,000</option>
                <option>$750,000</option>
                <option>$1,000,000</option>
              </select>
              <input
                type="text"
                name="physicalDamageCarrier"
                value={formData.physicalDamageCarrier}
                onChange={handleChange}
                placeholder="Insurance carrier name"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
              />
              <input
                type="text"
                name="physicalDamagePolicy"
                value={formData.physicalDamagePolicy}
                onChange={handleChange}
                placeholder="Policy number"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </>
          )}
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Workers Compensation</h2>
          <select
            name="workersComp"
            value={formData.workersComp}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          >
            <option>Not Required</option>
            <option>Required</option>
          </select>
          {formData.workersComp === 'Required' && (
            <>
              <input
                type="text"
                name="workersCompAmount"
                value={formData.workersCompAmount}
                onChange={handleChange}
                placeholder="Coverage amount"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
              />
              <input
                type="text"
                name="workersCompCarrier"
                value={formData.workersCompCarrier}
                onChange={handleChange}
                placeholder="Insurance carrier name"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
              />
              <input
                type="text"
                name="workersCompPolicy"
                value={formData.workersCompPolicy}
                onChange={handleChange}
                placeholder="Policy number"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </>
          )}
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Additional Requirements</h2>
          <textarea
            name="additionalInsurance"
            value={formData.additionalInsurance}
            onChange={handleChange}
            placeholder="Additional insurance types or requirements"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <textarea
            name="endorsements"
            value={formData.endorsements}
            onChange={handleChange}
            placeholder="Required endorsements or modifications"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Certificate & Verification</h2>
          <select
            name="certRequired"
            value={formData.certRequired}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          >
            <option>Yes</option>
            <option>No</option>
          </select>
          <input
            type="text"
            name="holderName"
            value={formData.holderName}
            onChange={handleChange}
            placeholder="Certificate holder name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-2 gap-4 mb-3">
            <div>
              <label className="block text-sm font-medium mb-2">Policy Renewal Date</label>
              <input
                type="date"
                name="renewalDate"
                value={formData.renewalDate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Next Audit Date</label>
              <input
                type="date"
                name="auditDate"
                value={formData.auditDate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
          <textarea
            name="notes"
            value={formData.notes}
            onChange={handleChange}
            placeholder="Additional notes or special requirements"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="flex gap-4">
          <button
            type="submit"
            className="flex-1 px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
          >
            Save Insurance Requirements
          </button>
          <Link href="/dashboard/forms" className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}

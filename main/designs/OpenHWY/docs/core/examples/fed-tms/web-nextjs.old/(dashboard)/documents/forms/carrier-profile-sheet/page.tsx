'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function CarrierProfileSheetPage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    legalBusinessName: '',
    dba: '',
    mcNumber: '',
    ein: '',
    daysInOperation: 'All Days',
    fleetSize: '',
    trailerTypes: '',
    equipment: '',
    yearsInBusiness: '',
    safetyRating: 'Satisfactory',
    oosViolations: 'No',
    insuranceCarrier: '',
    insuranceBroker: '',
    brokerContact: '',
    principalDriver: '',
    dispatcherName: '',
    dispatcherPhone: '',
    ownerName: '',
    ownerTitle: '',
    ownerPhone: '',
    specializations: '',
    certifications: '',
    capacities: '',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    addToast('Carrier Profile Sheet submitted successfully', 'success')
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <Link href="/dashboard/forms" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block">
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">Carrier Profile Sheet</h1>
          <p className="text-gray-400 mt-2">Comprehensive carrier operational profile</p>
        </div>
        <button
          onClick={() => addToast('Downloading Carrier Profile Sheet...', 'info')}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          📥 Download PDF
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Business Information</h2>
          <input
            type="text"
            name="legalBusinessName"
            value={formData.legalBusinessName}
            onChange={handleChange}
            placeholder="Legal business name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="dba"
            value={formData.dba}
            onChange={handleChange}
            placeholder="DBA (if different)"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-3 gap-4">
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
              name="ein"
              value={formData.ein}
              onChange={handleChange}
              placeholder="EIN"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="number"
              name="yearsInBusiness"
              value={formData.yearsInBusiness}
              onChange={handleChange}
              placeholder="Years in business"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Operational Details</h2>
          <div className="grid grid-cols-2 gap-4 mb-3">
            <div>
              <label className="block text-sm font-medium mb-2">Days in Operation</label>
              <select
                name="daysInOperation"
                value={formData.daysInOperation}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              >
                <option>All Days (24/7)</option>
                <option>Monday - Friday</option>
                <option>Monday - Saturday</option>
                <option>Custom Hours</option>
              </select>
            </div>
            <input
              type="number"
              name="fleetSize"
              value={formData.fleetSize}
              onChange={handleChange}
              placeholder="Fleet size (units)"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <textarea
            name="trailerTypes"
            value={formData.trailerTypes}
            onChange={handleChange}
            placeholder="Trailer types available (53' Dry Van, Refrigerated, Flatbed, etc.)"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <textarea
            name="equipment"
            value={formData.equipment}
            onChange={handleChange}
            placeholder="Additional equipment (Pallet jacks, liftgates, etc.)"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Safety & Compliance</h2>
          <div className="grid grid-cols-2 gap-4 mb-3">
            <select
              name="safetyRating"
              value={formData.safetyRating}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>Satisfactory</option>
              <option>Conditional</option>
              <option>Unsatisfactory</option>
              <option>Not Rated</option>
            </select>
            <select
              name="oosViolations"
              value={formData.oosViolations}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>No</option>
              <option>Yes</option>
            </select>
          </div>
          <textarea
            name="certifications"
            value={formData.certifications}
            onChange={handleChange}
            placeholder="Certifications and qualifications (Hazmat, Specialized, etc.)"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Insurance & Contact Information</h2>
          <input
            type="text"
            name="insuranceCarrier"
            value={formData.insuranceCarrier}
            onChange={handleChange}
            placeholder="Primary insurance carrier"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-2 gap-4 mb-3">
            <input
              type="text"
              name="insuranceBroker"
              value={formData.insuranceBroker}
              onChange={handleChange}
              placeholder="Insurance broker/agent"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="tel"
              name="brokerContact"
              value={formData.brokerContact}
              onChange={handleChange}
              placeholder="Broker phone"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <input
            type="text"
            name="principalDriver"
            value={formData.principalDriver}
            onChange={handleChange}
            placeholder="Principal driver name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="dispatcherName"
            value={formData.dispatcherName}
            onChange={handleChange}
            placeholder="Dispatcher name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="tel"
            name="dispatcherPhone"
            value={formData.dispatcherPhone}
            onChange={handleChange}
            placeholder="Dispatcher phone"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-2 gap-4">
            <input
              type="text"
              name="ownerName"
              value={formData.ownerName}
              onChange={handleChange}
              placeholder="Owner name"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="ownerTitle"
              value={formData.ownerTitle}
              onChange={handleChange}
              placeholder="Title/Position"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <input
            type="tel"
            name="ownerPhone"
            value={formData.ownerPhone}
            onChange={handleChange}
            placeholder="Owner phone"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Capabilities & Specializations</h2>
          <textarea
            name="specializations"
            value={formData.specializations}
            onChange={handleChange}
            placeholder="Specialized services (Expedited, White glove, etc.)"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <textarea
            name="capacities"
            value={formData.capacities}
            onChange={handleChange}
            placeholder="Load capacities and weight restrictions"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="flex gap-4">
          <button
            type="submit"
            className="flex-1 px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
          >
            Save Carrier Profile
          </button>
          <Link href="/dashboard/forms" className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}

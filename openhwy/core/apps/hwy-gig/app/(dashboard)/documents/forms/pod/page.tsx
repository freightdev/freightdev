'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useToast } from '@/lib/contexts/ToastContext'
import { useOperationalForm } from '@/lib/hooks'

export default function ProofOfDeliveryPage() {
  const { addToast } = useToast()
  const router = useRouter()
  const { submitPOD, loading, error } = useOperationalForm()
  const [formData, setFormData] = useState({
    podNumber: '',
    loadReference: '',
    deliveryDate: new Date().toISOString().split('T')[0],
    deliveryTime: '',
    carrierName: '',
    driverName: '',
    recipientName: '',
    recipientSignature: '',
    conditions: 'Goods received in good condition',
    damageNotes: '',
    mileage: '',
    fuelSurcharge: '',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await submitPOD(formData)
      // Redirect to forms page after successful submission
      router.push('/dashboard/forms')
    } catch (err) {
      // Error is already handled by useOperationalForm hook
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <Link href="/dashboard/forms" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block">
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">Proof of Delivery (POD)</h1>
          <p className="text-gray-400 mt-2">Delivery confirmation and shipment receipt</p>
        </div>
        <button
          onClick={() => addToast('Downloading POD...', 'info')}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          📥 Download PDF
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Delivery Information</h2>
          <div className="grid grid-cols-2 gap-4">
            <input
              type="text"
              name="podNumber"
              value={formData.podNumber}
              onChange={handleChange}
              placeholder="POD number"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="loadReference"
              value={formData.loadReference}
              onChange={handleChange}
              placeholder="Load reference"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="date"
              name="deliveryDate"
              value={formData.deliveryDate}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="time"
              name="deliveryTime"
              value={formData.deliveryTime}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Carrier & Recipient Information</h2>
          <input
            type="text"
            name="carrierName"
            value={formData.carrierName}
            onChange={handleChange}
            placeholder="Carrier name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="driverName"
            value={formData.driverName}
            onChange={handleChange}
            placeholder="Driver name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="recipientName"
            value={formData.recipientName}
            onChange={handleChange}
            placeholder="Recipient name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Delivery Status & Condition</h2>
          <select
            name="conditions"
            value={formData.conditions}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          >
            <option>Goods received in good condition</option>
            <option>Goods damaged</option>
            <option>Goods partially damaged</option>
            <option>Goods received with discrepancies</option>
          </select>
          <textarea
            name="damageNotes"
            value={formData.damageNotes}
            onChange={handleChange}
            placeholder="Notes about condition or damages (if any)"
            rows={3}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Additional Details</h2>
          <div className="grid grid-cols-2 gap-4">
            <input
              type="number"
              name="mileage"
              value={formData.mileage}
              onChange={handleChange}
              placeholder="Odometer reading"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="number"
              name="fuelSurcharge"
              value={formData.fuelSurcharge}
              onChange={handleChange}
              placeholder="Fuel surcharge"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        <div className="flex gap-4">
          <button
            type="submit"
            disabled={loading}
            className="flex-1 px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? 'Saving...' : 'Save POD'}
          </button>
          <Link href="/dashboard/forms" className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}

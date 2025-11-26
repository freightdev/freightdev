'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function BOLPage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    // BOL Details
    bolNumber: '',
    date: new Date().toISOString().split('T')[0],
    refNumber: '',

    // Shipper Information
    shipperName: '',
    shipperAddress: '',
    shipperCity: '',
    shipperState: '',
    shipperZip: '',
    shipperPhone: '',

    // Consignee Information
    consigneeName: '',
    consigneeAddress: '',
    consigneeCity: '',
    consigneeState: '',
    consigneeZip: '',
    consigneePhone: '',

    // Carrier Information
    carrierName: '',
    carrierMC: '',

    // Shipment Details
    commodityDescription: '',
    weight: '',
    weightUnit: 'lbs',
    pieces: '',
    hazmat: 'No',
    pickupDate: '',
    deliveryDate: '',
    freightCharge: '',
    specialInstructions: '',
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
    addToast('Bill of Lading saved successfully', 'success')
  }

  const handleDownload = () => {
    addToast('Downloading BOL...', 'info')
  }

  const handlePrint = () => {
    addToast('Opening print preview...', 'info')
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
          <h1 className="text-3xl font-bold">Bill of Lading (BOL)</h1>
          <p className="text-gray-400 mt-2">Shipping document - Proof of freight receipt and contract of carriage</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={handlePrint}
            className="px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all"
          >
            🖨️ Print
          </button>
          <button
            onClick={handleDownload}
            className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
          >
            📥 Download PDF
          </button>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* BOL HEADER */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Bill of Lading Details</h2>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">BOL Number</label>
              <input
                type="text"
                name="bolNumber"
                value={formData.bolNumber}
                onChange={handleChange}
                placeholder="Auto-generated"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Date</label>
              <input
                type="date"
                name="date"
                value={formData.date}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Reference Number</label>
              <input
                type="text"
                name="refNumber"
                value={formData.refNumber}
                onChange={handleChange}
                placeholder="Load reference"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
        </div>

        {/* SHIPPER INFORMATION */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Shipper Information</h2>

          <div>
            <label className="block text-sm font-medium mb-2">Shipper Name & Address</label>
            <input
              type="text"
              name="shipperName"
              value={formData.shipperName}
              onChange={handleChange}
              placeholder="Company name"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
            />
            <input
              type="text"
              name="shipperAddress"
              value={formData.shipperAddress}
              onChange={handleChange}
              placeholder="Street address"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
            />
          </div>

          <div className="grid grid-cols-4 gap-4">
            <input
              type="text"
              name="shipperCity"
              value={formData.shipperCity}
              onChange={handleChange}
              placeholder="City"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="shipperState"
              value={formData.shipperState}
              onChange={handleChange}
              placeholder="State"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="shipperZip"
              value={formData.shipperZip}
              onChange={handleChange}
              placeholder="ZIP"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="tel"
              name="shipperPhone"
              value={formData.shipperPhone}
              onChange={handleChange}
              placeholder="Phone"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        {/* CONSIGNEE INFORMATION */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Consignee Information (Delivery)</h2>

          <div>
            <label className="block text-sm font-medium mb-2">Consignee Name & Address</label>
            <input
              type="text"
              name="consigneeName"
              value={formData.consigneeName}
              onChange={handleChange}
              placeholder="Company name"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
            />
            <input
              type="text"
              name="consigneeAddress"
              value={formData.consigneeAddress}
              onChange={handleChange}
              placeholder="Street address"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
            />
          </div>

          <div className="grid grid-cols-4 gap-4">
            <input
              type="text"
              name="consigneeCity"
              value={formData.consigneeCity}
              onChange={handleChange}
              placeholder="City"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="consigneeState"
              value={formData.consigneeState}
              onChange={handleChange}
              placeholder="State"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="consigneeZip"
              value={formData.consigneeZip}
              onChange={handleChange}
              placeholder="ZIP"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="tel"
              name="consigneePhone"
              value={formData.consigneePhone}
              onChange={handleChange}
              placeholder="Phone"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        {/* CARRIER INFORMATION */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Carrier Information</h2>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Carrier Name</label>
              <input
                type="text"
                name="carrierName"
                value={formData.carrierName}
                onChange={handleChange}
                placeholder="Carrier name"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">MC Number</label>
              <input
                type="text"
                name="carrierMC"
                value={formData.carrierMC}
                onChange={handleChange}
                placeholder="MC-XXXXXX"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
        </div>

        {/* SHIPMENT DETAILS */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Shipment Details</h2>

          <div>
            <label className="block text-sm font-medium mb-2">Commodity Description</label>
            <textarea
              name="commodityDescription"
              value={formData.commodityDescription}
              onChange={handleChange}
              placeholder="Describe the cargo being shipped"
              rows={3}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>

          <div className="grid grid-cols-4 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Weight</label>
              <input
                type="number"
                name="weight"
                value={formData.weight}
                onChange={handleChange}
                placeholder="0"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Unit</label>
              <select
                name="weightUnit"
                value={formData.weightUnit}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              >
                <option>lbs</option>
                <option>kg</option>
                <option>tons</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Pieces</label>
              <input
                type="number"
                name="pieces"
                value={formData.pieces}
                onChange={handleChange}
                placeholder="0"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Hazmat</label>
              <select
                name="hazmat"
                value={formData.hazmat}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              >
                <option>No</option>
                <option>Yes</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Pickup Date</label>
              <input
                type="date"
                name="pickupDate"
                value={formData.pickupDate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Delivery Date</label>
              <input
                type="date"
                name="deliveryDate"
                value={formData.deliveryDate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Freight Charge</label>
              <input
                type="number"
                name="freightCharge"
                value={formData.freightCharge}
                onChange={handleChange}
                placeholder="0.00"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Special Instructions</label>
            <textarea
              name="specialInstructions"
              value={formData.specialInstructions}
              onChange={handleChange}
              placeholder="Any special handling or delivery instructions"
              rows={2}
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
            Save BOL
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

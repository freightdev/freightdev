'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function RateConfirmationPage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    confirmationNumber: '',
    loadNumber: '',
    date: new Date().toISOString().split('T')[0],
    pickupLocation: '',
    pickupDate: '',
    pickupTime: '',
    deliveryLocation: '',
    deliveryDate: '',
    deliveryWindow: '8am-5pm',
    commodity: '',
    weight: '',
    pieces: '',
    dimensions: '',
    hazmat: 'No',
    temperature: 'Ambient',
    specialHandling: '',
    carrierName: '',
    driverName: '',
    truckNumber: '',
    trailerNumber: '',
    lineHaulRate: '',
    fuelSurcharge: '',
    accessorialCharges: '',
    insurance: '',
    detentionCharge: '',
    totalFreight: '',
    shipper: '',
    shipperContact: '',
    consignee: '',
    consigneeContact: '',
    paymentTerms: 'Net 30',
    specialInstructions: '',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    addToast('Rate Confirmation submitted successfully', 'success')
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <Link href="/dashboard/forms" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block">
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">Rate Confirmation</h1>
          <p className="text-gray-400 mt-2">Load pricing and transportation rates confirmation</p>
        </div>
        <button
          onClick={() => addToast('Downloading Rate Confirmation...', 'info')}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          📥 Download PDF
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Confirmation Details</h2>
          <div className="grid grid-cols-3 gap-4 mb-3">
            <input
              type="text"
              name="confirmationNumber"
              value={formData.confirmationNumber}
              onChange={handleChange}
              placeholder="Confirmation number"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="loadNumber"
              value={formData.loadNumber}
              onChange={handleChange}
              placeholder="Load number"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="date"
              name="date"
              value={formData.date}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Pickup Information</h2>
          <input
            type="text"
            name="pickupLocation"
            value={formData.pickupLocation}
            onChange={handleChange}
            placeholder="Pickup location/address"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-3 gap-4">
            <input
              type="date"
              name="pickupDate"
              value={formData.pickupDate}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="time"
              name="pickupTime"
              value={formData.pickupTime}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="shipper"
              value={formData.shipper}
              onChange={handleChange}
              placeholder="Shipper name"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <input
            type="tel"
            name="shipperContact"
            value={formData.shipperContact}
            onChange={handleChange}
            placeholder="Shipper contact/phone"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Delivery Information</h2>
          <input
            type="text"
            name="deliveryLocation"
            value={formData.deliveryLocation}
            onChange={handleChange}
            placeholder="Delivery location/address"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-3 gap-4 mb-3">
            <input
              type="date"
              name="deliveryDate"
              value={formData.deliveryDate}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <select
              name="deliveryWindow"
              value={formData.deliveryWindow}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>8am-5pm</option>
              <option>9am-5pm</option>
              <option>7am-3pm</option>
              <option>Appointment</option>
            </select>
            <input
              type="text"
              name="consignee"
              value={formData.consignee}
              onChange={handleChange}
              placeholder="Consignee name"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <input
            type="tel"
            name="consigneeContact"
            value={formData.consigneeContact}
            onChange={handleChange}
            placeholder="Consignee contact/phone"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Commodity Details</h2>
          <input
            type="text"
            name="commodity"
            value={formData.commodity}
            onChange={handleChange}
            placeholder="Commodity description"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-4 gap-4 mb-3">
            <input
              type="number"
              name="weight"
              value={formData.weight}
              onChange={handleChange}
              placeholder="Weight (lbs)"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="number"
              name="pieces"
              value={formData.pieces}
              onChange={handleChange}
              placeholder="Pieces/Pallets"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <select
              name="hazmat"
              value={formData.hazmat}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>No</option>
              <option>Yes</option>
            </select>
            <select
              name="temperature"
              value={formData.temperature}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>Ambient</option>
              <option>Refrigerated</option>
              <option>Frozen</option>
              <option>Temperature Controlled</option>
            </select>
          </div>
          <input
            type="text"
            name="dimensions"
            value={formData.dimensions}
            onChange={handleChange}
            placeholder="Dimensions (if applicable)"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <textarea
            name="specialHandling"
            value={formData.specialHandling}
            onChange={handleChange}
            placeholder="Special handling instructions"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Carrier & Equipment</h2>
          <div className="grid grid-cols-2 gap-4 mb-3">
            <input
              type="text"
              name="carrierName"
              value={formData.carrierName}
              onChange={handleChange}
              placeholder="Carrier name"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="driverName"
              value={formData.driverName}
              onChange={handleChange}
              placeholder="Driver name"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <input
              type="text"
              name="truckNumber"
              value={formData.truckNumber}
              onChange={handleChange}
              placeholder="Truck/Tractor number"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="trailerNumber"
              value={formData.trailerNumber}
              onChange={handleChange}
              placeholder="Trailer number"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Freight Charges</h2>
          <div className="grid grid-cols-2 gap-4 mb-3">
            <div>
              <label className="block text-sm font-medium mb-2">Line Haul Rate</label>
              <input
                type="number"
                name="lineHaulRate"
                value={formData.lineHaulRate}
                onChange={handleChange}
                placeholder="$"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Fuel Surcharge</label>
              <input
                type="number"
                name="fuelSurcharge"
                value={formData.fuelSurcharge}
                onChange={handleChange}
                placeholder="$"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4 mb-3">
            <div>
              <label className="block text-sm font-medium mb-2">Accessorial Charges</label>
              <input
                type="number"
                name="accessorialCharges"
                value={formData.accessorialCharges}
                onChange={handleChange}
                placeholder="$"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Insurance/Fees</label>
              <input
                type="number"
                name="insurance"
                value={formData.insurance}
                onChange={handleChange}
                placeholder="$"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4 mb-3">
            <div>
              <label className="block text-sm font-medium mb-2">Detention Charge</label>
              <input
                type="number"
                name="detentionCharge"
                value={formData.detentionCharge}
                onChange={handleChange}
                placeholder="$"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Total Freight Charge</label>
              <input
                type="number"
                name="totalFreight"
                value={formData.totalFreight}
                onChange={handleChange}
                placeholder="$"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
          <select
            name="paymentTerms"
            value={formData.paymentTerms}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          >
            <option>Net 15</option>
            <option>Net 30</option>
            <option>Net 45</option>
            <option>COD</option>
            <option>Prepaid</option>
          </select>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Special Instructions</h2>
          <textarea
            name="specialInstructions"
            value={formData.specialInstructions}
            onChange={handleChange}
            placeholder="Any additional notes or special instructions"
            rows={4}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="flex gap-4">
          <button
            type="submit"
            className="flex-1 px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
          >
            Confirm Rate
          </button>
          <Link href="/dashboard/forms" className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}

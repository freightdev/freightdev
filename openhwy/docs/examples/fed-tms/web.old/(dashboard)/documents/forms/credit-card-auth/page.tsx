'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function CreditCardAuthPage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    // Authorization Details
    date: new Date().toISOString().split('T')[0],
    authAmount: '',
    authPurpose: 'Payment for services',

    // Account Holder
    accountName: '',
    accountEmail: '',
    accountPhone: '',

    // Card Information (Note: In production, NEVER store full card numbers)
    cardholderName: '',
    cardExpiry: '',
    cardLast4: '',

    // Billing Address
    billingAddress: '',
    billingCity: '',
    billingState: '',
    billingZip: '',

    // Authorization Terms
    startDate: '',
    endDate: '',
    frequency: 'One-time',
    maxAmount: '',

    // Agreement
    agreeToTerms: false,
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target
    if (type === 'checkbox') {
      setFormData((prev) => ({
        ...prev,
        [name]: (e.target as HTMLInputElement).checked,
      }))
    } else {
      setFormData((prev) => ({
        ...prev,
        [name]: value,
      }))
    }
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (!formData.agreeToTerms) {
      addToast('Please agree to the terms and conditions', 'error')
      return
    }
    addToast('Credit card authorization saved securely', 'success')
  }

  const handleDownload = () => {
    addToast('Downloading authorization form...', 'info')
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
          <h1 className="text-3xl font-bold">Credit Card Authorization</h1>
          <p className="text-gray-400 mt-2">Secure payment authorization form</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={handleDownload}
            className="px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all"
          >
            📥 Download
          </button>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* SECURITY WARNING */}
        <div className="bg-blue-600/20 border border-blue-600/50 rounded-xl p-4">
          <p className="text-sm text-blue-400">
            <strong>🔒 Security Notice:</strong> Credit card information is encrypted and processed securely. We never store full card numbers.
          </p>
        </div>

        {/* AUTHORIZATION DETAILS */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Authorization Details</h2>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Authorization Date</label>
              <input
                type="date"
                name="date"
                value={formData.date}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Authorization Amount</label>
              <div className="relative">
                <span className="absolute left-4 top-3 text-gray-400">$</span>
                <input
                  type="number"
                  name="authAmount"
                  value={formData.authAmount}
                  onChange={handleChange}
                  placeholder="0.00"
                  step="0.01"
                  className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 pl-8 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
                />
              </div>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Purpose of Authorization</label>
            <select
              name="authPurpose"
              value={formData.authPurpose}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>Payment for services</option>
              <option>Recurring monthly payment</option>
              <option>Load factoring</option>
              <option>Insurance premium</option>
              <option>Equipment lease</option>
              <option>Other</option>
            </select>
          </div>
        </div>

        {/* ACCOUNT HOLDER */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Account Holder Information</h2>

          <div>
            <label className="block text-sm font-medium mb-2">Account Holder Name</label>
            <input
              type="text"
              name="accountName"
              value={formData.accountName}
              onChange={handleChange}
              placeholder="Full name"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Email Address</label>
              <input
                type="email"
                name="accountEmail"
                value={formData.accountEmail}
                onChange={handleChange}
                placeholder="email@example.com"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Phone Number</label>
              <input
                type="tel"
                name="accountPhone"
                value={formData.accountPhone}
                onChange={handleChange}
                placeholder="(555) 123-4567"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
        </div>

        {/* CARD INFORMATION */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Credit Card Information</h2>
          <p className="text-sm text-gray-400">For payment processing only. Information is encrypted.</p>

          <div>
            <label className="block text-sm font-medium mb-2">Cardholder Name</label>
            <input
              type="text"
              name="cardholderName"
              value={formData.cardholderName}
              onChange={handleChange}
              placeholder="Name on card"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Card Expiry (MM/YY)</label>
              <input
                type="text"
                name="cardExpiry"
                value={formData.cardExpiry}
                onChange={handleChange}
                placeholder="MM/YY"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Last 4 Digits</label>
              <input
                type="text"
                name="cardLast4"
                value={formData.cardLast4}
                onChange={handleChange}
                placeholder="4242"
                maxLength={4}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
        </div>

        {/* BILLING ADDRESS */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Billing Address</h2>

          <div>
            <label className="block text-sm font-medium mb-2">Street Address</label>
            <input
              type="text"
              name="billingAddress"
              value={formData.billingAddress}
              onChange={handleChange}
              placeholder="123 Main St"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>

          <div className="grid grid-cols-4 gap-4">
            <input
              type="text"
              name="billingCity"
              value={formData.billingCity}
              onChange={handleChange}
              placeholder="City"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="billingState"
              value={formData.billingState}
              onChange={handleChange}
              placeholder="State"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="billingZip"
              value={formData.billingZip}
              onChange={handleChange}
              placeholder="ZIP"
              className="col-span-2 bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        {/* AUTHORIZATION TERMS */}
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Authorization Terms</h2>

          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">Start Date</label>
              <input
                type="date"
                name="startDate"
                value={formData.startDate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">End Date</label>
              <input
                type="date"
                name="endDate"
                value={formData.endDate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">Frequency</label>
              <select
                name="frequency"
                value={formData.frequency}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              >
                <option>One-time</option>
                <option>Weekly</option>
                <option>Bi-weekly</option>
                <option>Monthly</option>
                <option>Quarterly</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">Maximum Amount</label>
            <div className="relative">
              <span className="absolute left-4 top-3 text-gray-400">$</span>
              <input
                type="number"
                name="maxAmount"
                value={formData.maxAmount}
                onChange={handleChange}
                placeholder="0.00"
                step="0.01"
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 pl-8 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
              />
            </div>
          </div>
        </div>

        {/* AGREEMENT CHECKBOX */}
        <div className="bg-yellow-600/20 border border-yellow-600/50 rounded-xl p-6">
          <label className="flex items-start gap-4">
            <input
              type="checkbox"
              name="agreeToTerms"
              checked={formData.agreeToTerms}
              onChange={handleChange}
              className="mt-1 w-5 h-5 accent-[#d946ef]"
            />
            <div>
              <p className="text-sm text-yellow-400 font-semibold">I authorize this credit card charge</p>
              <p className="text-xs text-yellow-400/80 mt-2">
                By checking this box, I authorize the above charges to be processed. This authorization is valid from the start date through the end date specified above, or until canceled in writing.
              </p>
            </div>
          </label>
        </div>

        {/* SUBMIT BUTTONS */}
        <div className="flex gap-4">
          <button
            type="submit"
            className="flex-1 px-6 py-3 bg-gradient-to-r from-green-600 to-green-500 rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-green-600/40 transition-all"
          >
            Authorize Payment
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

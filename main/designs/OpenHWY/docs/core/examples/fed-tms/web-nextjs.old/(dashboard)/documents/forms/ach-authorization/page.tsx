'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useToast } from '@/lib/contexts/ToastContext'
import { useFinancialForm } from '@/lib/hooks'

export default function ACHAuthorizationPage() {
  const { addToast } = useToast()
  const router = useRouter()
  const { submitACHAuth, loading, error } = useFinancialForm()
  const [formData, setFormData] = useState({
    accountName: '',
    accountEmail: '',
    bankName: '',
    accountType: 'Checking',
    routingNumber: '',
    accountNumber: '',
    accountHolder: '',
    frequency: 'Weekly',
    amount: '',
    agreementDate: new Date().toISOString().split('T')[0],
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      await submitACHAuth(formData)
      // Redirect to forms page after successful submission
      router.push('/dashboard/forms')
    } catch (err) {
      // Error is already handled by useFinancialForm hook
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <Link href="/dashboard/forms" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block">
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">ACH Bank Transfer Authorization</h1>
          <p className="text-gray-400 mt-2">Automated Clearing House (ACH) direct deposit authorization</p>
        </div>
        <button
          onClick={() => addToast('Downloading ACH Authorization...', 'info')}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          📥 Download PDF
        </button>
      </div>

      <div className="bg-blue-600/20 border border-blue-600/50 rounded-xl p-4">
        <p className="text-sm text-blue-400">
          <strong>🔒 Security:</strong> Bank information is encrypted. We only use this for direct deposits.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Account Information</h2>
          <input
            type="text"
            name="accountName"
            value={formData.accountName}
            onChange={handleChange}
            placeholder="Account holder name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="email"
            name="accountEmail"
            value={formData.accountEmail}
            onChange={handleChange}
            placeholder="Email address"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Bank Information</h2>
          <input
            type="text"
            name="bankName"
            value={formData.bankName}
            onChange={handleChange}
            placeholder="Bank name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-2 gap-4">
            <select
              name="accountType"
              value={formData.accountType}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>Checking</option>
              <option>Savings</option>
            </select>
            <input
              type="text"
              name="routingNumber"
              value={formData.routingNumber}
              onChange={handleChange}
              placeholder="Routing number (9 digits)"
              maxLength={9}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="accountNumber"
              value={formData.accountNumber}
              onChange={handleChange}
              placeholder="Account number"
              className="col-span-2 bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Payment Settings</h2>
          <div className="grid grid-cols-2 gap-4">
            <select
              name="frequency"
              value={formData.frequency}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>Weekly</option>
              <option>Bi-weekly</option>
              <option>Monthly</option>
            </select>
            <input
              type="number"
              name="amount"
              value={formData.amount}
              onChange={handleChange}
              placeholder="Amount ($)"
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <input
            type="date"
            name="agreementDate"
            value={formData.agreementDate}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-yellow-600/20 border border-yellow-600/50 rounded-xl p-4">
          <p className="text-xs text-yellow-400">
            <strong>⚠️ Verification:</strong> I authorize the company to initiate ACH transfers to my bank account. I understand this authorization is valid for all periodic payments specified above.
          </p>
        </div>

        <div className="flex gap-4">
          <button
            type="submit"
            disabled={loading}
            className="flex-1 px-6 py-3 bg-gradient-to-r from-green-600 to-green-500 rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-green-600/40 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? 'Authorizing...' : 'Authorize ACH'}
          </button>
          <Link href="/dashboard/forms" className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}

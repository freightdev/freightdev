'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { useToast } from '@/lib/contexts/ToastContext'

export default function BrokerAgreementPage() {
  const { addToast } = useToast()
  const [formData, setFormData] = useState({
    brokerCompany: '',
    brokerAddress: '',
    brokerCity: '',
    brokerState: '',
    brokerZip: '',
    brokerPhone: '',
    brokerEmail: '',
    brokerMC: '',
    carrierName: '',
    carrierMC: '',
    contactPerson: '',
    contactPhone: '',
    agreementDate: new Date().toISOString().split('T')[0],
    effectiveDate: new Date().toISOString().split('T')[0],
    commissionRate: '12%',
    paymentTerms: 'Net 30',
    loadQuality: 'All Available',
    trafficLanes: '',
    exclusions: '',
    tenderTerms: '2 hours',
    factoryTerms: 'FOB',
    insuranceRequired: 'Yes',
    minimumInsurance: '$1,000,000',
    brokerCompensation: 'Percent',
    loadPaymentMethod: 'ACH',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    addToast('Broker Agreement submitted successfully', 'success')
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <Link href="/dashboard/forms" className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold mb-4 block">
            ← Back to Forms
          </Link>
          <h1 className="text-3xl font-bold">Broker Agreement</h1>
          <p className="text-gray-400 mt-2">Load authority and freight brokerage agreement</p>
        </div>
        <button
          onClick={() => addToast('Downloading Broker Agreement...', 'info')}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          📥 Download PDF
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Broker Information</h2>
          <input
            type="text"
            name="brokerCompany"
            value={formData.brokerCompany}
            onChange={handleChange}
            placeholder="Broker company name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="brokerAddress"
            value={formData.brokerAddress}
            onChange={handleChange}
            placeholder="Street address"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-4 gap-4 mb-3">
            <input
              type="text"
              name="brokerCity"
              value={formData.brokerCity}
              onChange={handleChange}
              placeholder="City"
              className="col-span-2 bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="brokerState"
              value={formData.brokerState}
              onChange={handleChange}
              placeholder="State"
              className="bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
            <input
              type="text"
              name="brokerZip"
              value={formData.brokerZip}
              onChange={handleChange}
              placeholder="ZIP"
              className="bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            />
          </div>
          <input
            type="tel"
            name="brokerPhone"
            value={formData.brokerPhone}
            onChange={handleChange}
            placeholder="Phone number"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="email"
            name="brokerEmail"
            value={formData.brokerEmail}
            onChange={handleChange}
            placeholder="Email address"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="brokerMC"
            value={formData.brokerMC}
            onChange={handleChange}
            placeholder="Broker MC Authority number"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Carrier Information</h2>
          <input
            type="text"
            name="carrierName"
            value={formData.carrierName}
            onChange={handleChange}
            placeholder="Carrier/Motor Carrier name"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="carrierMC"
            value={formData.carrierMC}
            onChange={handleChange}
            placeholder="Carrier MC Authority number"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="text"
            name="contactPerson"
            value={formData.contactPerson}
            onChange={handleChange}
            placeholder="Primary contact person"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <input
            type="tel"
            name="contactPhone"
            value={formData.contactPhone}
            onChange={handleChange}
            placeholder="Contact phone"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Agreement Terms</h2>
          <div className="grid grid-cols-2 gap-4 mb-3">
            <div>
              <label className="block text-sm font-medium mb-2">Agreement Date</label>
              <input
                type="date"
                name="agreementDate"
                value={formData.agreementDate}
                onChange={handleChange}
                className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
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
          <div className="grid grid-cols-2 gap-4">
            <select
              name="commissionRate"
              value={formData.commissionRate}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>8%</option>
              <option>10%</option>
              <option>12%</option>
              <option>15%</option>
              <option>18%</option>
              <option>20%</option>
            </select>
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
            </select>
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Load & Service Terms</h2>
          <select
            name="loadQuality"
            value={formData.loadQuality}
            onChange={handleChange}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          >
            <option>All Available</option>
            <option>Preferred Lanes Only</option>
            <option>Pre-Approved Loads</option>
            <option>Premium Loads</option>
          </select>
          <input
            type="text"
            name="trafficLanes"
            value={formData.trafficLanes}
            onChange={handleChange}
            placeholder="Preferred lanes/territories (comma separated)"
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <textarea
            name="exclusions"
            value={formData.exclusions}
            onChange={handleChange}
            placeholder="Load exclusions or restrictions"
            rows={2}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors mb-3"
          />
          <div className="grid grid-cols-2 gap-4">
            <select
              name="tenderTerms"
              value={formData.tenderTerms}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>1 hour</option>
              <option>2 hours</option>
              <option>4 hours</option>
              <option>No limit</option>
            </select>
            <select
              name="factoryTerms"
              value={formData.factoryTerms}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>FOB Origin</option>
              <option>FOB Destination</option>
              <option>Prepaid</option>
              <option>Collect</option>
            </select>
          </div>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
          <h2 className="text-xl font-bold">Insurance & Payment</h2>
          <div className="grid grid-cols-2 gap-4 mb-3">
            <select
              name="insuranceRequired"
              value={formData.insuranceRequired}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>Yes</option>
              <option>No</option>
            </select>
            <select
              name="minimumInsurance"
              value={formData.minimumInsurance}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>$500,000</option>
              <option>$750,000</option>
              <option>$1,000,000</option>
              <option>$2,000,000</option>
            </select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <select
              name="brokerCompensation"
              value={formData.brokerCompensation}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>Percent</option>
              <option>Per Load</option>
              <option>Flat Rate</option>
            </select>
            <select
              name="loadPaymentMethod"
              value={formData.loadPaymentMethod}
              onChange={handleChange}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option>ACH</option>
              <option>Check</option>
              <option>Wire Transfer</option>
              <option>Credit Card</option>
            </select>
          </div>
        </div>

        <div className="flex gap-4">
          <button
            type="submit"
            className="flex-1 px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
          >
            Submit Broker Agreement
          </button>
          <Link href="/dashboard/forms" className="flex-1 px-6 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all text-center">
            Cancel
          </Link>
        </div>
      </form>
    </div>
  )
}

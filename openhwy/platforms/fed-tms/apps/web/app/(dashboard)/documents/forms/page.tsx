'use client'

import React from 'react'
import Link from 'next/link'

const FORM_CATEGORIES = [
  {
    id: 'agreements',
    name: 'Dispatcher Agreements',
    description: 'Driver and dispatcher service agreements',
    icon: '📋',
    forms: [
      { id: 'full-dispatcher', name: 'Full Dispatcher Agreement', subtitle: '8% service fee' },
      { id: 'half-dispatcher', name: 'Half Dispatcher Agreement', subtitle: '4% service fee' },
      { id: 'load-finder', name: 'Load Finder Agreement', subtitle: '12% service fee' },
      { id: 'paperwork-only', name: 'Paperwork Only Agreement', subtitle: '3% service fee' },
      { id: 'rate-agreement', name: 'Rate Agreement', subtitle: 'Custom rate negotiation' },
    ],
  },
  {
    id: 'carrier',
    name: 'Carrier & Broker Forms',
    description: 'Carrier setup and broker agreements',
    icon: '🚚',
    forms: [
      { id: 'carrier-agreement-packet', name: 'Carrier Agreement Packet', subtitle: 'Complete carrier onboarding' },
      { id: 'carrier-profile-sheet', name: 'Carrier Profile Sheet', subtitle: 'Company information form' },
      { id: 'broker-agreement', name: 'Broker Agreement', subtitle: 'Freight broker contracts' },
    ],
  },
  {
    id: 'operations',
    name: 'Operational Forms',
    description: 'Daily operations and shipping documents',
    icon: '📦',
    forms: [
      { id: 'bol', name: 'Bill of Lading (BOL)', subtitle: 'Shipping document template' },
      { id: 'pod', name: 'Proof of Delivery', subtitle: 'Delivery confirmation' },
      { id: 'rate-confirmation', name: 'Rate Confirmation', subtitle: 'Load rate agreement' },
    ],
  },
  {
    id: 'financial',
    name: 'Financial & Tax Forms',
    description: 'Payment authorization and tax documents',
    icon: '💰',
    forms: [
      { id: 'credit-card-auth', name: 'Credit Card Authorization', subtitle: 'Payment authorization form' },
      { id: 'w9', name: 'Form W-9', subtitle: 'Tax ID form' },
      { id: 'ach-authorization', name: 'ACH Authorization', subtitle: 'Bank transfer authorization' },
    ],
  },
  {
    id: 'compliance',
    name: 'Compliance Documents',
    description: 'Insurance and regulatory documents',
    icon: '✅',
    forms: [
      { id: 'certificate-insurance', name: 'Certificate of Insurance', subtitle: 'COI document' },
      { id: 'mc-authority', name: 'MC Authority', subtitle: 'Motor Carrier authority' },
      { id: 'insurance-requirements', name: 'Insurance Requirements', subtitle: 'Coverage requirements' },
    ],
  },
]

export default function FormsPage() {
  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Business Forms & Agreements</h1>
          <p className="text-gray-400 mt-2">Manage dispatcher agreements, carrier forms, and operational documents</p>
        </div>
        <Link
          href="/dashboard/forms/new"
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          + Create Form
        </Link>
      </div>

      {/* FORM CATEGORIES */}
      <div className="space-y-8">
        {FORM_CATEGORIES.map((category) => (
          <div key={category.id} className="space-y-4">
            {/* CATEGORY HEADER */}
            <div className="flex items-center gap-3 pb-4 border-b border-white/10">
              <span className="text-3xl">{category.icon}</span>
              <div>
                <h2 className="text-2xl font-bold">{category.name}</h2>
                <p className="text-sm text-gray-400">{category.description}</p>
              </div>
            </div>

            {/* FORMS GRID */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {category.forms.map((form) => (
                <Link
                  key={form.id}
                  href={`/dashboard/forms/${form.id}`}
                  className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 hover:border-[#d946ef]/50 transition-all hover:shadow-lg hover:shadow-[#d946ef]/20 group"
                >
                  <div className="flex justify-between items-start mb-3">
                    <div>
                      <h3 className="text-lg font-bold group-hover:text-[#d946ef] transition-colors">{form.name}</h3>
                      <p className="text-sm text-gray-400 mt-1">{form.subtitle}</p>
                    </div>
                    <span className="text-[#d946ef] opacity-0 group-hover:opacity-100 transition-opacity">→</span>
                  </div>
                  <div className="flex gap-2 mt-4">
                    <button
                      onClick={(e) => {
                        e.preventDefault()
                        // View/Edit form
                      }}
                      className="flex-1 px-3 py-2 text-xs bg-white/10 border border-white/20 rounded-lg text-white hover:bg-white/20 transition-colors"
                    >
                      View
                    </button>
                    <button
                      onClick={(e) => {
                        e.preventDefault()
                        // Download form
                      }}
                      className="flex-1 px-3 py-2 text-xs bg-white/10 border border-white/20 rounded-lg text-white hover:bg-white/20 transition-colors"
                    >
                      Download
                    </button>
                  </div>
                </Link>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* QUICK STATS */}
      <div className="grid grid-cols-4 gap-4 pt-8 border-t border-white/10">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-4 text-center">
          <p className="text-gray-400 text-sm mb-2">Total Forms</p>
          <p className="text-2xl font-bold">{FORM_CATEGORIES.reduce((sum, cat) => sum + cat.forms.length, 0)}</p>
        </div>
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-4 text-center">
          <p className="text-gray-400 text-sm mb-2">Categories</p>
          <p className="text-2xl font-bold">{FORM_CATEGORIES.length}</p>
        </div>
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-4 text-center">
          <p className="text-gray-400 text-sm mb-2">Active</p>
          <p className="text-2xl font-bold">{FORM_CATEGORIES.reduce((sum, cat) => sum + cat.forms.length, 0)}</p>
        </div>
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-4 text-center">
          <p className="text-gray-400 text-sm mb-2">Coverage</p>
          <p className="text-2xl font-bold">100%</p>
        </div>
      </div>
    </div>
  )
}

'use client'

import React, { useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { useInvoice } from '@/lib/hooks'
import { useToast } from '@/lib/contexts/ToastContext'

export default function InvoiceDetailPage() {
  const params = useParams()
  const invoiceId = params.id as string
  const { invoice, loading, error, refetch } = useInvoice(invoiceId, { autoFetch: true })
  const { addToast } = useToast()

  const [showPaymentForm, setShowPaymentForm] = useState(false)

  React.useEffect(() => {
    if (error) {
      addToast(error, 'error')
    }
  }, [error, addToast])

  if (loading) {
    return (
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-12 text-center">
        <div className="flex items-center justify-center gap-3 mb-4">
          <div className="w-8 h-8 border-4 border-[#d946ef]/20 border-t-[#d946ef] rounded-full animate-spin"></div>
          <p className="text-gray-400">Loading invoice details...</p>
        </div>
      </div>
    )
  }

  if (error || !invoice) {
    return (
      <div className="space-y-6">
        <Link
          href="/dashboard/invoicing"
          className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
        >
          ← Back
        </Link>
        <div className="bg-red-600/20 border border-red-600/50 rounded-xl p-6 text-center">
          <p className="text-red-400 mb-4">{error || 'Invoice not found'}</p>
          <button
            onClick={refetch}
            className="px-4 py-2 rounded-lg bg-red-600/20 border border-red-600/50 text-red-400 font-semibold hover:bg-red-600/30 transition-colors"
          >
            Try Again
          </button>
        </div>
      </div>
    )
  }

  const lineItems = invoice.line_items || []
  const payments = invoice.payment_history || []

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-4">
          <Link
            href="/dashboard/invoicing"
            className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
          >
            ← Back
          </Link>
          <div>
            <h1 className="text-3xl font-bold">{invoice.number || 'Invoice'}</h1>
            <p className="text-gray-400">Driver: {invoice.driver_name || 'Unknown'}</p>
          </div>
        </div>
        <span
          className={`text-xs font-semibold px-3 py-1 rounded-full ${
            invoice.status === 'paid'
              ? 'bg-green-600/20 text-green-400 border border-green-600/50'
              : invoice.status === 'partial'
              ? 'bg-blue-600/20 text-blue-400 border border-blue-600/50'
              : 'bg-yellow-600/20 text-yellow-400 border border-yellow-600/50'
          }`}
        >
          {invoice.status}
        </span>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* MAIN CONTENT */}
        <div className="col-span-2 space-y-6">
          {/* INVOICE SUMMARY */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-8">
            <div className="flex justify-between items-start mb-8 pb-8 border-b border-white/10">
              <div>
                <p className="text-gray-400 text-sm mb-2">Invoice To</p>
                <p className="font-semibold text-lg">{invoice.driver_name || 'Unknown'}</p>
                <p className="text-sm text-gray-400">Driver ID: {invoice.driver_id || 'N/A'}</p>
              </div>
              <div className="text-right">
                <p className="text-gray-400 text-sm mb-2">Invoice Details</p>
                <p className="font-semibold">Invoice #: {invoice.number || 'N/A'}</p>
                <p className="text-sm text-gray-400">Date: {invoice.created_at || 'N/A'}</p>
                <p className="text-sm text-gray-400">Due: {invoice.due_date || 'N/A'}</p>
              </div>
            </div>

            {/* LINE ITEMS */}
            <div className="mb-8">
              <h3 className="font-bold mb-4">Loads</h3>
              {lineItems && lineItems.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-white/10">
                        <th className="text-left py-3 px-4 text-xs font-semibold text-gray-400 uppercase">
                          Load
                        </th>
                        <th className="text-left py-3 px-4 text-xs font-semibold text-gray-400 uppercase">
                          Route
                        </th>
                        <th className="text-right py-3 px-4 text-xs font-semibold text-gray-400 uppercase">
                          Amount
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {lineItems.map((item, idx) => (
                        <tr key={idx} className="border-b border-white/5 hover:bg-white/5">
                          <td className="py-3 px-4">
                            <Link
                              href={`/dashboard/loads/${item.load_id}`}
                              className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
                            >
                              {item.load_reference}
                            </Link>
                          </td>
                          <td className="py-3 px-4">
                            <p className="text-sm text-gray-400">{item.route || 'N/A'}</p>
                            <p className="text-xs text-gray-600">{item.distance ? `${item.distance} miles` : 'N/A'}</p>
                          </td>
                          <td className="py-3 px-4 text-right font-semibold">${item.rate?.toLocaleString() || '0'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <p className="text-gray-400 text-sm text-center py-4">No line items</p>
              )}
            </div>

            {/* TOTALS */}
            <div className="space-y-3 pt-4 border-t border-white/10">
              <div className="flex justify-between items-center">
                <span className="text-gray-400">Subtotal</span>
                <span className="font-semibold">${(invoice.subtotal || invoice.amount).toLocaleString()}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-400">Tax ({invoice.tax_rate || 0}%)</span>
                <span className="font-semibold">${(invoice.tax || 0).toLocaleString()}</span>
              </div>
              <div className="flex justify-between items-center py-3 border-t border-white/10 text-lg">
                <span className="font-bold">Total</span>
                <span className="font-bold text-green-400">${(invoice.total || invoice.amount).toLocaleString()}</span>
              </div>
            </div>
          </div>

          {/* PAYMENT HISTORY */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <h3 className="font-bold mb-4">Payment History</h3>
            {payments && payments.length > 0 ? (
              <div className="space-y-3">
                {payments.map((payment, idx) => (
                  <div key={idx} className="p-4 bg-white/5 rounded-lg border border-white/10">
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="font-semibold">${payment.amount?.toLocaleString() || '0'}</p>
                        <p className="text-sm text-gray-400">{payment.payment_method || 'N/A'}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-sm text-gray-400">{payment.paid_at || 'N/A'}</p>
                        <span className="text-xs font-semibold px-2 py-1 rounded-full bg-green-600/20 text-green-400">
                          Completed
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-400 text-center py-8">No payments yet</p>
            )}
          </div>
        </div>

        {/* SIDEBAR */}
        <div className="space-y-6">
          {/* SUMMARY CARDS */}
          <div className="space-y-4">
            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
              <p className="text-gray-400 text-sm mb-2">Total Amount</p>
              <p className="text-3xl font-bold">${(invoice.total || invoice.amount).toLocaleString()}</p>
            </div>

            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
              <p className="text-gray-400 text-sm mb-2">Amount Paid</p>
              <p className="text-3xl font-bold text-green-400">${(invoice.paid_amount || 0).toLocaleString()}</p>
            </div>

            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
              <p className="text-gray-400 text-sm mb-2">Outstanding</p>
              <p className="text-3xl font-bold text-orange-400">${(invoice.remaining_amount || (invoice.total || invoice.amount) - (invoice.paid_amount || 0)).toLocaleString()}</p>
            </div>
          </div>

          {/* PAYMENT SECTION */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <h3 className="font-bold mb-4">Record Payment</h3>
            {!showPaymentForm ? (
              <button
                onClick={() => setShowPaymentForm(true)}
                className="w-full px-4 py-3 bg-gradient-to-r from-green-600 to-green-500 rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-green-600/40 transition-all"
              >
                💵 Record Payment
              </button>
            ) : (
              <div className="space-y-3">
                <div>
                  <label className="block text-sm font-medium mb-2">Amount</label>
                  <input
                    type="number"
                    placeholder={`0 - ${invoice.remaining}`}
                    max={invoice.remaining}
                    className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-green-500/50 transition-colors"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium mb-2">Payment Method</label>
                  <select className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-green-500/50 transition-colors">
                    <option>Bank Transfer</option>
                    <option>Check</option>
                    <option>Credit Card</option>
                    <option>Cash</option>
                  </select>
                </div>
                <button className="w-full px-4 py-3 bg-gradient-to-r from-green-600 to-green-500 rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-green-600/40 transition-all">
                  Confirm Payment
                </button>
                <button
                  onClick={() => setShowPaymentForm(false)}
                  className="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white font-semibold hover:bg-white/20 transition-all"
                >
                  Cancel
                </button>
              </div>
            )}
          </div>

          {/* ACTIONS */}
          <div className="space-y-2">
            <button className="w-full px-4 py-3 rounded-lg bg-white/10 border border-white/20 hover:border-[#d946ef]/50 text-white font-semibold transition-all">
              📥 Download Invoice
            </button>
            <button className="w-full px-4 py-3 rounded-lg bg-white/10 border border-white/20 hover:border-[#d946ef]/50 text-white font-semibold transition-all">
              📧 Send Email
            </button>
            <button className="w-full px-4 py-3 rounded-lg bg-white/10 border border-white/20 hover:border-[#d946ef]/50 text-white font-semibold transition-all">
              🖨️ Print
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

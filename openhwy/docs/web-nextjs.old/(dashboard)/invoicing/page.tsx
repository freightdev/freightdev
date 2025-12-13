'use client'

import React, { useState, useMemo } from 'react'
import Link from 'next/link'
import { useInvoices } from '@/lib/hooks'
import { useToast } from '@/lib/contexts/ToastContext'

export default function InvoicingPage() {
  const [searchTerm, setSearchTerm] = useState('')
  const [filterStatus, setFilterStatus] = useState('all')
  const { invoices, loading, error, refetch } = useInvoices({
    search: searchTerm,
    status: filterStatus,
    autoFetch: true,
  })
  const { addToast } = useToast()

  React.useEffect(() => {
    if (error) {
      addToast(error, 'error')
    }
  }, [error, addToast])

  const stats = useMemo(() => {
    const total = invoices.reduce((sum, inv) => sum + inv.amount, 0)
    const totalPaid = invoices.reduce((sum, inv) => sum + inv.paid_amount, 0)
    return { total, totalPaid, outstanding: total - totalPaid }
  }, [invoices])

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'paid':
        return 'bg-green-600/20 text-green-400 border border-green-600/50'
      case 'pending':
        return 'bg-yellow-600/20 text-yellow-400 border border-yellow-600/50'
      case 'partial':
        return 'bg-blue-600/20 text-blue-400 border border-blue-600/50'
      case 'cancelled':
        return 'bg-red-600/20 text-red-400 border border-red-600/50'
      default:
        return 'bg-gray-600/20 text-gray-400 border border-gray-600/50'
    }
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Invoicing</h1>
        <Link
          href="/dashboard/invoicing/new"
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          + Create Invoice
        </Link>
      </div>

      {/* STATS GRID */}
      <div className="grid grid-cols-3 gap-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 hover:border-[#d946ef]/50 transition-all hover:shadow-lg hover:shadow-[#d946ef]/20">
          <div className="flex justify-between items-start mb-4">
            <div className="text-3xl bg-gradient-to-br from-purple-600 to-purple-400 bg-clip-text text-transparent">
              💰
            </div>
          </div>
          <h3 className="text-gray-400 text-sm font-medium mb-2">Total Amount</h3>
          <p className="text-3xl font-bold">${stats.total.toLocaleString()}</p>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 hover:border-[#d946ef]/50 transition-all hover:shadow-lg hover:shadow-[#d946ef]/20">
          <div className="flex justify-between items-start mb-4">
            <div className="text-3xl bg-gradient-to-br from-green-600 to-green-400 bg-clip-text text-transparent">
              ✓
            </div>
          </div>
          <h3 className="text-gray-400 text-sm font-medium mb-2">Amount Paid</h3>
          <p className="text-3xl font-bold text-green-400">${stats.totalPaid.toLocaleString()}</p>
        </div>

        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 hover:border-[#d946ef]/50 transition-all hover:shadow-lg hover:shadow-[#d946ef]/20">
          <div className="flex justify-between items-start mb-4">
            <div className="text-3xl bg-gradient-to-br from-orange-600 to-orange-400 bg-clip-text text-transparent">
              ⚠️
            </div>
          </div>
          <h3 className="text-gray-400 text-sm font-medium mb-2">Outstanding</h3>
          <p className="text-3xl font-bold text-orange-400">${stats.outstanding.toLocaleString()}</p>
        </div>
      </div>

      {/* FILTERS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 flex gap-4">
        <div className="flex-1">
          <input
            type="text"
            placeholder="Search by invoice ID or driver..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>
        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          className="bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors cursor-pointer"
        >
          <option value="all">All Statuses</option>
          <option value="paid">Paid</option>
          <option value="pending">Pending</option>
          <option value="partial">Partial</option>
          <option value="cancelled">Cancelled</option>
        </select>
      </div>

      {/* LOADING STATE */}
      {loading && (
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-12 text-center">
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="w-8 h-8 border-4 border-[#d946ef]/20 border-t-[#d946ef] rounded-full animate-spin"></div>
            <p className="text-gray-400">Loading invoices...</p>
          </div>
        </div>
      )}

      {/* ERROR STATE */}
      {error && !loading && (
        <div className="bg-red-600/20 border border-red-600/50 rounded-xl p-6 text-center">
          <p className="text-red-400 mb-4">{error}</p>
          <button
            onClick={refetch}
            className="px-4 py-2 rounded-lg bg-red-600/20 border border-red-600/50 text-red-400 font-semibold hover:bg-red-600/30 transition-colors"
          >
            Try Again
          </button>
        </div>
      )}

      {/* INVOICES TABLE */}
      {!loading && !error && (
        <>
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-white/10">
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Invoice ID
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Driver
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Amount
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Paid
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Remaining
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Status
                    </th>
                    <th className="text-left py-4 px-4 text-xs font-semibold text-gray-400 uppercase">
                      Due Date
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {invoices.map((invoice) => (
                    <tr
                      key={invoice.id}
                      className="border-b border-white/5 hover:bg-white/5 transition-colors"
                    >
                      <td className="py-4 px-4">
                        <Link
                          href={`/dashboard/invoicing/${invoice.id}`}
                          className="font-semibold text-[#d946ef] hover:text-[#d946ef]/80"
                        >
                          {invoice.number}
                        </Link>
                      </td>
                      <td className="py-4 px-4 text-sm">{invoice.driver_name || 'Unknown'}</td>
                      <td className="py-4 px-4 text-sm font-semibold">${invoice.amount.toLocaleString()}</td>
                      <td className="py-4 px-4 text-sm text-green-400 font-semibold">
                        ${invoice.paid_amount.toLocaleString()}
                      </td>
                      <td className="py-4 px-4 text-sm text-orange-400 font-semibold">
                        ${invoice.remaining_amount.toLocaleString()}
                      </td>
                      <td className="py-4 px-4">
                        <span className={`text-xs font-semibold px-3 py-1 rounded-full ${getStatusColor(invoice.status)}`}>
                          {invoice.status}
                        </span>
                      </td>
                      <td className="py-4 px-4 text-sm text-gray-400">{invoice.due_date}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {invoices.length === 0 && (
            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-12 text-center">
              <p className="text-gray-400">No invoices found matching your criteria</p>
            </div>
          )}
        </>
      )}
    </div>
  )
}

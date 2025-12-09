'use client'

import React, { useState } from 'react'
import Link from 'next/link'

export default function DocumentsPage() {
  const [searchTerm, setSearchTerm] = useState('')
  const [filterType, setFilterType] = useState('all')

  const documents = [
    {
      id: 'doc-1',
      name: 'CDL License - John Smith',
      type: 'license',
      driver: 'John Smith',
      category: 'Driver Documents',
      uploadedAt: '2025-10-15',
      size: '2.4 MB',
      status: 'verified',
      expiresAt: '2026-06-30',
    },
    {
      id: 'doc-2',
      name: 'Insurance Certificate - Vehicle ABC-1234',
      type: 'insurance',
      driver: 'N/A',
      category: 'Vehicle Documents',
      uploadedAt: '2025-11-01',
      size: '1.8 MB',
      status: 'verified',
      expiresAt: '2026-12-31',
    },
    {
      id: 'doc-3',
      name: 'Load Bill of Lading - LOAD-001',
      type: 'bill',
      driver: 'John Smith',
      category: 'Load Documents',
      uploadedAt: '2025-11-25',
      size: '0.8 MB',
      status: 'pending',
      expiresAt: 'N/A',
    },
    {
      id: 'doc-4',
      name: 'Inspection Report - Sarah Johnson',
      type: 'inspection',
      driver: 'Sarah Johnson',
      category: 'Driver Documents',
      uploadedAt: '2025-11-20',
      size: '3.2 MB',
      status: 'verified',
      expiresAt: '2026-11-20',
    },
    {
      id: 'doc-5',
      name: 'Hazmat Certification - Mike Davis',
      type: 'hazmat',
      driver: 'Mike Davis',
      category: 'Driver Documents',
      uploadedAt: '2025-09-10',
      size: '1.5 MB',
      status: 'expired',
      expiresAt: '2025-09-10',
    },
    {
      id: 'doc-6',
      name: 'Proof of Delivery - LOAD-002',
      type: 'delivery',
      driver: 'Sarah Johnson',
      category: 'Load Documents',
      uploadedAt: '2025-11-24',
      size: '4.1 MB',
      status: 'verified',
      expiresAt: 'N/A',
    },
  ]

  const filteredDocuments = documents.filter((doc) => {
    const matchesSearch = doc.name.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesType = filterType === 'all' || doc.type === filterType

    return matchesSearch && matchesType
  })

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'verified':
        return 'bg-green-600/20 text-green-400 border border-green-600/50'
      case 'pending':
        return 'bg-yellow-600/20 text-yellow-400 border border-yellow-600/50'
      case 'expired':
        return 'bg-red-600/20 text-red-400 border border-red-600/50'
      default:
        return 'bg-gray-600/20 text-gray-400 border border-gray-600/50'
    }
  }

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'license':
        return '🆔'
      case 'insurance':
        return '📋'
      case 'bill':
        return '📄'
      case 'inspection':
        return '✓'
      case 'hazmat':
        return '⚠️'
      case 'delivery':
        return '📦'
      default:
        return '📄'
    }
  }

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex justify-between items-center">
        <h1 className="text-3xl font-bold">Documents</h1>
        <button className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all">
          + Upload Document
        </button>
      </div>

      {/* STATS */}
      <div className="grid grid-cols-4 gap-6">
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
          <p className="text-gray-400 text-sm mb-2">Total Documents</p>
          <p className="text-3xl font-bold">{documents.length}</p>
        </div>
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
          <p className="text-gray-400 text-sm mb-2">Verified</p>
          <p className="text-3xl font-bold text-green-400">
            {documents.filter((d) => d.status === 'verified').length}
          </p>
        </div>
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
          <p className="text-gray-400 text-sm mb-2">Pending</p>
          <p className="text-3xl font-bold text-yellow-400">
            {documents.filter((d) => d.status === 'pending').length}
          </p>
        </div>
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
          <p className="text-gray-400 text-sm mb-2">Expired</p>
          <p className="text-3xl font-bold text-red-400">
            {documents.filter((d) => d.status === 'expired').length}
          </p>
        </div>
      </div>

      {/* FILTERS */}
      <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 flex gap-4">
        <div className="flex-1">
          <input
            type="text"
            placeholder="Search documents..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white placeholder:text-gray-500 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
          />
        </div>
        <select
          value={filterType}
          onChange={(e) => setFilterType(e.target.value)}
          className="bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-[#d946ef]/50 transition-colors cursor-pointer"
        >
          <option value="all">All Types</option>
          <option value="license">License</option>
          <option value="insurance">Insurance</option>
          <option value="bill">Bill of Lading</option>
          <option value="inspection">Inspection</option>
          <option value="hazmat">Hazmat Cert</option>
          <option value="delivery">Delivery Proof</option>
        </select>
      </div>

      {/* DOCUMENTS GRID */}
      <div className="grid grid-cols-1 gap-4">
        {filteredDocuments.map((doc) => (
          <div
            key={doc.id}
            className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 hover:border-[#d946ef]/50 transition-all hover:shadow-lg hover:shadow-[#d946ef]/20"
          >
            <div className="flex items-start justify-between gap-4">
              <div className="flex items-start gap-4 flex-1">
                <div className="text-4xl flex-shrink-0">{getTypeIcon(doc.type)}</div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-3 mb-2">
                    <h3 className="text-lg font-bold truncate">{doc.name}</h3>
                    <span className={`text-xs font-semibold px-3 py-1 rounded-full ${getStatusColor(doc.status)}`}>
                      {doc.status}
                    </span>
                  </div>
                  <div className="grid grid-cols-2 gap-4 text-sm text-gray-400 mb-3">
                    <div>
                      <p className="text-xs text-gray-500 mb-1">Category</p>
                      <p>{doc.category}</p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 mb-1">Driver/Vehicle</p>
                      <p>{doc.driver}</p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 mb-1">Uploaded</p>
                      <p>{doc.uploadedAt}</p>
                    </div>
                    <div>
                      <p className="text-xs text-gray-500 mb-1">Expires</p>
                      <p className={doc.expiresAt === 'N/A' ? '' : doc.status === 'expired' ? 'text-red-400' : ''}>
                        {doc.expiresAt}
                      </p>
                    </div>
                  </div>
                  <div className="text-xs text-gray-500">Size: {doc.size}</div>
                </div>
              </div>

              <div className="flex gap-2 flex-shrink-0">
                <button className="px-4 py-2 rounded-lg bg-white/10 border border-white/20 hover:border-[#d946ef]/50 text-white text-sm font-semibold transition-all">
                  📥 Download
                </button>
                <button className="px-4 py-2 rounded-lg bg-white/10 border border-white/20 hover:border-[#d946ef]/50 text-white text-sm font-semibold transition-all">
                  👁️ Preview
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {filteredDocuments.length === 0 && (
        <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-12 text-center">
          <p className="text-gray-400">No documents found matching your criteria</p>
        </div>
      )}
    </div>
  )
}

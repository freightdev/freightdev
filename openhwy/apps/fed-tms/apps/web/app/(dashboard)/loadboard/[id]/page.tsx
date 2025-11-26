'use client'

import React, { useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { useLoad } from '@/lib/hooks'
import { useToast } from '@/lib/contexts/ToastContext'

export default function LoadDetailPage() {
  const params = useParams()
  const loadId = params.id as string
  const { load, loading, error, refetch } = useLoad(loadId, { autoFetch: true })
  const { addToast } = useToast()

  const [newStatus, setNewStatus] = useState(load?.status || 'pending')

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
          <p className="text-gray-400">Loading load details...</p>
        </div>
      </div>
    )
  }

  if (error || !load) {
    return (
      <div className="space-y-6">
        <Link
          href="/dashboard/loads"
          className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
        >
          ← Back
        </Link>
        <div className="bg-red-600/20 border border-red-600/50 rounded-xl p-6 text-center">
          <p className="text-red-400 mb-4">{error || 'Load not found'}</p>
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

  const tracking = load.tracking_history || []
  const documents = load.documents || []

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-4">
          <Link
            href="/dashboard/loads"
            className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
          >
            ← Back
          </Link>
          <h1 className="text-3xl font-bold">{load.reference || 'Load'}</h1>
        </div>
        <span
          className={`text-xs font-semibold px-3 py-1 rounded-full ${
            load.status === 'in_transit'
              ? 'bg-blue-600/20 text-blue-400 border border-blue-600/50'
              : load.status === 'delivered'
              ? 'bg-green-600/20 text-green-400 border border-green-600/50'
              : 'bg-yellow-600/20 text-yellow-400 border border-yellow-600/50'
          }`}
        >
          {load.status.replace('_', ' ')}
        </span>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* MAIN CONTENT */}
        <div className="col-span-2 space-y-6">
          {/* ROUTE OVERVIEW */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <h3 className="font-bold mb-6">Route Overview</h3>

            {/* PROGRESS */}
            <div className="mb-6">
              <div className="flex justify-between items-center mb-2">
                <p className="text-sm text-gray-400">Route Progress</p>
                <p className="font-semibold">{load.progress || 0}%</p>
              </div>
              <div className="w-full bg-white/10 rounded-full h-3 overflow-hidden">
                <div
                  className="bg-gradient-to-r from-blue-500 to-blue-400 h-full"
                  style={{ width: `${load.progress || 0}%` }}
                ></div>
              </div>
            </div>

            {/* ROUTE MAP PLACEHOLDER */}
            <div className="bg-white/5 rounded-lg p-8 border border-white/10 flex items-center justify-center aspect-video mb-6">
              <div className="text-center">
                <div className="text-4xl mb-2">🗺️</div>
                <p className="text-gray-400">Route Map</p>
                <p className="text-xs text-gray-600 mt-2">({load.origin} → {load.destination})</p>
              </div>
            </div>

            {/* ORIGIN & DESTINATION */}
            <div className="grid grid-cols-2 gap-4">
              <div className="p-4 bg-white/5 rounded-lg border border-white/10">
                <p className="text-xs text-gray-500 mb-2">📍 Pickup Location</p>
                <p className="font-semibold mb-1">{load.origin || 'N/A'}</p>
                <p className="text-sm text-gray-400">Picked up at {load.pickup_time || 'TBD'}</p>
              </div>
              <div className="p-4 bg-white/5 rounded-lg border border-white/10">
                <p className="text-xs text-gray-500 mb-2">🎯 Delivery Location</p>
                <p className="font-semibold mb-1">{load.destination || 'N/A'}</p>
                <p className="text-sm text-gray-400">Deadline: {load.delivery_deadline || 'TBD'}</p>
              </div>
            </div>
          </div>

          {/* CARGO INFO */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <h3 className="font-bold mb-4">Cargo Information</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-gray-500 mb-1">Cargo Type</p>
                <p className="font-semibold">{load.cargo_type || 'N/A'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">Weight</p>
                <p className="font-semibold">{load.cargo_weight || 'N/A'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">Dimensions</p>
                <p className="font-semibold">{load.cargo_dimensions || 'N/A'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">Distance</p>
                <p className="font-semibold">{load.distance ? `${load.distance} miles` : 'N/A'}</p>
              </div>
            </div>
            {load.special_notes && (
              <div className="mt-4 pt-4 border-t border-white/10">
                <p className="text-xs text-gray-500 mb-2">Special Notes</p>
                <p className="text-sm">{load.special_notes}</p>
              </div>
            )}
          </div>

          {/* TRACKING HISTORY */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <h3 className="font-bold mb-4">Tracking History</h3>
            {tracking && tracking.length > 0 ? (
              <div className="space-y-3">
                {tracking.map((entry, idx) => (
                  <div key={idx} className="flex gap-4">
                    <div className="flex flex-col items-center">
                      <div className="w-3 h-3 rounded-full bg-[#d946ef] mt-2"></div>
                      {idx < tracking.length - 1 && <div className="w-0.5 h-8 bg-white/20"></div>}
                    </div>
                    <div className="flex-1 py-2">
                      <p className="font-semibold text-sm">{entry.status}</p>
                      <p className="text-xs text-gray-400">{entry.location || 'Unknown'}</p>
                      <p className="text-xs text-gray-600">{entry.timestamp}</p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-400 text-sm">No tracking history available</p>
            )}
          </div>
        </div>

        {/* SIDEBAR */}
        <div className="space-y-6">
          {/* DRIVER ASSIGNMENT */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <h3 className="font-bold mb-4">Driver Assignment</h3>
            {load.driver_id ? (
              <Link
                href={`/dashboard/drivers/${load.driver_id}`}
                className="block p-4 rounded-lg bg-white/5 border border-white/10 hover:border-[#d946ef]/50 transition-all"
              >
                <p className="font-semibold mb-1">{load.driver_details?.name || 'Unknown Driver'}</p>
                <p className="text-sm text-gray-400 mb-2">{load.driver_details?.vehicle || 'N/A'}</p>
                <p className="text-xs text-gray-600">Plate: {load.driver_details?.license_plate || 'N/A'}</p>
              </Link>
            ) : (
              <div className="p-4 rounded-lg bg-white/5 border border-white/10">
                <p className="text-gray-400 text-sm">No driver assigned</p>
              </div>
            )}
          </div>

          {/* LOAD DETAILS */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h3 className="font-bold mb-4">Load Details</h3>
            <div className="space-y-4">
              <div>
                <p className="text-xs text-gray-500 mb-1">Load Rate</p>
                <p className="font-semibold text-lg text-green-400">${load.rate?.toLocaleString() || '0'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">ETA</p>
                <p className="font-semibold">{load.eta || 'TBD'}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500 mb-1">Created</p>
                <p className="font-semibold text-sm">{load.created_at || 'N/A'}</p>
              </div>
            </div>
          </div>

          {/* STATUS UPDATE */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <h3 className="font-bold mb-4">Update Status</h3>
            <select
              value={newStatus}
              onChange={(e) => setNewStatus(e.target.value)}
              className="w-full bg-white/10 border border-white/20 rounded-lg px-4 py-3 text-white mb-4 focus:outline-none focus:border-[#d946ef]/50 transition-colors"
            >
              <option value="pending">Pending</option>
              <option value="in_transit">In Transit</option>
              <option value="delivered">Delivered</option>
              <option value="cancelled">Cancelled</option>
            </select>
            <button className="w-full px-4 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all">
              Update Status
            </button>
          </div>

          {/* DOCUMENTS */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <h3 className="font-bold mb-4">Documents ({documents.length})</h3>
            {documents && documents.length > 0 ? (
              <div className="space-y-2">
                {documents.map((doc, idx) => (
                  <div key={idx} className="p-3 bg-white/5 rounded-lg border border-white/10">
                    <p className="font-semibold text-sm mb-1">{doc.name}</p>
                    <div className="flex justify-between items-center text-xs">
                      <span className="text-gray-600">{doc.uploaded_at}</span>
                      <a
                        href={doc.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-blue-400 hover:text-blue-300"
                      >
                        Download
                      </a>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-gray-400 text-sm">No documents uploaded</p>
            )}
          </div>

          {/* ACTIONS */}
          <div className="space-y-2">
            <button className="w-full px-4 py-3 rounded-lg bg-white/10 border border-white/20 hover:border-[#d946ef]/50 text-white font-semibold transition-all">
              📋 Generate Invoice
            </button>
            <button className="w-full px-4 py-3 rounded-lg bg-white/10 border border-white/20 hover:border-[#d946ef]/50 text-white font-semibold transition-all">
              📥 Download Documents
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

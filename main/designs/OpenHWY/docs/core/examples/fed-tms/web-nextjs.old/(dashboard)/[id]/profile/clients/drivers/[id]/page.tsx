'use client'

import React, { useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { useDriver } from '@/lib/hooks'
import { useToast } from '@/lib/contexts/ToastContext'

export default function DriverDetailPage() {
  const params = useParams()
  const driverId = params.id as string
  const { driver, loading, error, refetch } = useDriver(driverId, { autoFetch: true })
  const { addToast } = useToast()

  const [editMode, setEditMode] = useState(false)

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
          <p className="text-gray-400">Loading driver details...</p>
        </div>
      </div>
    )
  }

  if (error || !driver) {
    return (
      <div className="space-y-6">
        <Link
          href="/dashboard/drivers"
          className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
        >
          ← Back
        </Link>
        <div className="bg-red-600/20 border border-red-600/50 rounded-xl p-6 text-center">
          <p className="text-red-400 mb-4">{error || 'Driver not found'}</p>
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

  const displayName = driver.name || `${driver.first_name} ${driver.last_name}`.trim() || 'Unknown'
  const recentLoads = driver.recent_loads || []
  const documents = driver.documents || []

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <div className="flex justify-between items-center">
        <div className="flex items-center gap-4">
          <Link
            href="/dashboard/drivers"
            className="text-[#d946ef] hover:text-[#d946ef]/80 font-semibold"
          >
            ← Back
          </Link>
          <h1 className="text-3xl font-bold">{displayName}</h1>
        </div>
        <button
          onClick={() => setEditMode(!editMode)}
          className="px-6 py-3 bg-gradient-to-r from-[#d946ef] to-[#a855f7] rounded-lg text-white font-semibold hover:shadow-lg hover:shadow-[#d946ef]/40 transition-all"
        >
          {editMode ? 'Save' : '✏️ Edit'}
        </button>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* MAIN CONTENT */}
        <div className="col-span-2 space-y-6">
          {/* DRIVER INFO */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-6">
            {/* STATUS & RATING */}
            <div className="flex justify-between items-start pb-6 border-b border-white/10">
              <div>
                <div className="flex items-center gap-3 mb-2">
                  <span
                    className={`text-xs font-semibold px-3 py-1 rounded-full ${
                      driver.status === 'active'
                        ? 'bg-green-600/20 text-green-400 border border-green-600/50'
                        : 'bg-gray-600/20 text-gray-400 border border-gray-600/50'
                    }`}
                  >
                    {driver.status}
                  </span>
                </div>
                <p className="text-gray-400">Driver License: {driver.license || 'N/A'}</p>
              </div>
              <div className="text-right">
                <p className="text-4xl font-bold text-yellow-400 mb-2">{driver.rating || 'N/A'}⭐</p>
                <p className="text-sm text-gray-400">{driver.completed_loads || 0} completed loads</p>
              </div>
            </div>

            {/* CONTACT INFO */}
            <div>
              <h3 className="font-bold mb-4">Contact Information</h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-xs text-gray-500 mb-1">Email</p>
                  <p className="font-semibold">{driver.email || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 mb-1">Phone</p>
                  <p className="font-semibold">{driver.phone || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 mb-1">Address</p>
                  <p className="font-semibold text-sm">{driver.address || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 mb-1">Emergency Contact</p>
                  <p className="font-semibold">{driver.emergency_contact || 'N/A'}</p>
                </div>
              </div>
            </div>

            {/* VEHICLE INFO */}
            <div className="pt-6 border-t border-white/10">
              <h3 className="font-bold mb-4">Vehicle Information</h3>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-xs text-gray-500 mb-1">Vehicle</p>
                  <p className="font-semibold">{driver.vehicle || 'N/A'}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 mb-1">License Plate</p>
                  <p className="font-semibold">{driver.license_plate || 'N/A'}</p>
                </div>
              </div>
            </div>
          </div>

          {/* CERTIFICATIONS */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h3 className="font-bold mb-4">Certifications & Licenses</h3>
            {driver.certifications && driver.certifications.length > 0 ? (
              <div className="space-y-3">
                {driver.certifications.map((cert, idx) => {
                  const statusColor = cert.status === 'valid' ? 'text-green-400' : cert.status === 'expiring_soon' ? 'text-yellow-400' : 'text-red-400'
                  const statusIcon = cert.status === 'valid' ? '✓' : cert.status === 'expiring_soon' ? '⚠️' : '❌'
                  return (
                    <div key={idx} className="flex justify-between items-center p-3 bg-white/5 rounded-lg">
                      <div>
                        <p className="font-semibold">{cert.name}</p>
                        <p className="text-sm text-gray-400">Expires: {cert.expiry_date}</p>
                      </div>
                      <span className={`${statusColor} font-semibold`}>{statusIcon} {cert.status}</span>
                    </div>
                  )
                })}
              </div>
            ) : (
              <p className="text-gray-400 text-sm">No certifications found</p>
            )}
          </div>

          {/* RECENT LOADS */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6">
            <h3 className="font-bold mb-4">Recent Loads</h3>
            {recentLoads && recentLoads.length > 0 ? (
              <div className="space-y-3">
                {recentLoads.map((load) => (
                  <Link
                    key={load.id}
                    href={`/dashboard/loads/${load.id}`}
                    className="block p-4 bg-white/5 rounded-lg border border-white/10 hover:border-[#d946ef]/50 transition-all"
                  >
                    <div className="flex justify-between items-start mb-2">
                      <div>
                        <p className="font-semibold text-[#d946ef]">{load.reference}</p>
                        <p className="text-sm text-gray-400">{load.origin} → {load.destination}</p>
                      </div>
                      <div className="text-right">
                        <p className="font-semibold">${load.rate.toLocaleString()}</p>
                        <span
                          className={`text-xs px-2 py-1 rounded-full ${
                            load.status === 'in_transit'
                              ? 'bg-blue-600/20 text-blue-400'
                              : 'bg-green-600/20 text-green-400'
                          }`}
                        >
                          {load.status.replace('_', ' ')}
                        </span>
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            ) : (
              <p className="text-gray-400 text-sm">No recent loads</p>
            )}
          </div>
        </div>

        {/* SIDEBAR */}
        <div className="space-y-6">
          {/* KEY METRICS */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
            <h3 className="font-bold mb-4">Performance</h3>
            {driver.performance_metrics ? (
              <div className="space-y-4">
                <div>
                  <p className="text-xs text-gray-500 mb-2">On-Time Delivery Rate</p>
                  <div className="w-full bg-white/10 rounded-full h-2 overflow-hidden">
                    <div className="bg-gradient-to-r from-green-500 to-green-400 h-full" style={{ width: `${driver.performance_metrics.on_time_delivery_rate}%` }}></div>
                  </div>
                  <p className="text-xs text-gray-400 mt-1">{driver.performance_metrics.on_time_delivery_rate}%</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 mb-2">Vehicle Utilization</p>
                  <div className="w-full bg-white/10 rounded-full h-2 overflow-hidden">
                    <div className="bg-gradient-to-r from-blue-500 to-blue-400 h-full" style={{ width: `${driver.performance_metrics.vehicle_utilization_rate}%` }}></div>
                  </div>
                  <p className="text-xs text-gray-400 mt-1">{driver.performance_metrics.vehicle_utilization_rate}%</p>
                </div>
              </div>
            ) : (
              <p className="text-gray-400 text-sm">No performance data available</p>
            )}
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
                      <span className="text-gray-500">{doc.uploaded_at}</span>
                      <span className={doc.verified ? 'text-green-400' : 'text-yellow-400'}>
                        {doc.verified ? '✓ Verified' : '⏳ Pending'}
                      </span>
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
              📞 Call Driver
            </button>
            <button className="w-full px-4 py-3 rounded-lg bg-white/10 border border-white/20 hover:border-[#d946ef]/50 text-white font-semibold transition-all">
              💬 Send Message
            </button>
            <button className="w-full px-4 py-3 rounded-lg bg-red-600/20 border border-red-600/50 hover:bg-red-600/30 text-red-400 font-semibold transition-all">
              🚫 Suspend Driver
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

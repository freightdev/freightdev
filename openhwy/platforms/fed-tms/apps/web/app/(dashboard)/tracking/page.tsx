'use client'

import React, { useState } from 'react'
import Link from 'next/link'

export default function LiveTrackingPage() {
  const [selectedLoad, setSelectedLoad] = useState('LOAD-001')

  const activeLoads = [
    {
      id: 'LOAD-001',
      reference: 'NY-BOS-001',
      driver: 'John Smith',
      vehicle: '2020 Freightliner',
      plate: 'ABC-1234',
      from: 'New York, NY',
      to: 'Boston, MA',
      status: 'in_transit',
      latitude: 40.7128,
      longitude: -74.006,
      speed: 65,
      nextStop: 'Rest area, Connecticut',
      eta: '2 hours',
      progress: 65,
      distance: '215 miles',
      remaining: '75 miles',
      fuel: 85,
      temperature: 68,
    },
    {
      id: 'LOAD-004',
      reference: 'SEA-PDX-001',
      driver: 'Emma Wilson',
      vehicle: '2022 Kenworth',
      plate: 'GHI-3456',
      from: 'Seattle, WA',
      to: 'Portland, OR',
      status: 'in_transit',
      latitude: 47.6062,
      longitude: -122.3321,
      speed: 58,
      nextStop: 'Fuel stop, Olympia WA',
      eta: '4 hours',
      progress: 40,
      distance: '175 miles',
      remaining: '105 miles',
      fuel: 45,
      temperature: 62,
    },
  ]

  const selectedLoadData = activeLoads.find((load) => load.id === selectedLoad)

  return (
    <div className="space-y-6">
      {/* HEADER */}
      <h1 className="text-3xl font-bold">Live Tracking</h1>

      <div className="grid grid-cols-3 gap-6">
        {/* MAP SECTION */}
        <div className="col-span-2 space-y-6">
          {/* MAP PLACEHOLDER */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 aspect-video flex items-center justify-center">
            <div className="text-center">
              <div className="text-6xl mb-4">🗺️</div>
              <p className="text-gray-400 mb-2">Live GPS Tracking Map</p>
              <p className="text-sm text-gray-500">
                Lat: {selectedLoadData?.latitude.toFixed(4)} | Lon:{' '}
                {selectedLoadData?.longitude.toFixed(4)}
              </p>
              <p className="text-xs text-gray-600 mt-4">
                (Integrate with Mapbox, Google Maps, or OpenStreetMap)
              </p>
            </div>
          </div>

          {/* LOAD DETAILS CARD */}
          {selectedLoadData && (
            <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
              <div className="flex justify-between items-start">
                <div>
                  <h2 className="text-2xl font-bold mb-2">{selectedLoadData.reference}</h2>
                  <p className="text-gray-400">
                    {selectedLoadData.from} → {selectedLoadData.to}
                  </p>
                </div>
                <span className="bg-blue-600/20 text-blue-400 border border-blue-600/50 text-xs font-semibold px-3 py-1 rounded-full">
                  In Transit
                </span>
              </div>

              <div className="grid grid-cols-2 gap-4 pt-4 border-t border-white/10">
                <div>
                  <p className="text-xs text-gray-500 mb-1">Driver</p>
                  <p className="font-semibold">{selectedLoadData.driver}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 mb-1">Vehicle</p>
                  <p className="font-semibold">{selectedLoadData.vehicle}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 mb-1">Speed</p>
                  <p className="font-semibold text-blue-400">{selectedLoadData.speed} mph</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500 mb-1">Fuel</p>
                  <p className="font-semibold text-green-400">{selectedLoadData.fuel}%</p>
                </div>
              </div>

              {/* PROGRESS BAR */}
              <div className="pt-4 border-t border-white/10">
                <div className="flex justify-between items-center mb-2">
                  <p className="text-sm text-gray-400">Route Progress</p>
                  <p className="text-sm font-semibold">{selectedLoadData.progress}%</p>
                </div>
                <div className="w-full bg-white/10 rounded-full h-3 overflow-hidden">
                  <div
                    className="bg-gradient-to-r from-blue-500 to-blue-400 h-full"
                    style={{ width: `${selectedLoadData.progress}%` }}
                  ></div>
                </div>
                <div className="flex justify-between mt-2 text-xs text-gray-500">
                  <span>{selectedLoadData.remaining} remaining</span>
                  <span>ETA: {selectedLoadData.eta}</span>
                </div>
              </div>

              {/* NEXT STOP */}
              <div className="bg-white/5 rounded-lg p-4 border border-white/10">
                <p className="text-xs text-gray-500 mb-2">Next Stop</p>
                <p className="font-semibold mb-1">{selectedLoadData.nextStop}</p>
                <p className="text-sm text-gray-400">ETA: {selectedLoadData.eta}</p>
              </div>
            </div>
          )}
        </div>

        {/* SIDEBAR */}
        <div className="space-y-6">
          {/* ACTIVE LOADS */}
          <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-3">
            <h3 className="font-bold mb-4">Active Loads ({activeLoads.length})</h3>
            {activeLoads.map((load) => (
              <button
                key={load.id}
                onClick={() => setSelectedLoad(load.id)}
                className={`w-full text-left p-3 rounded-lg border transition-all ${
                  selectedLoad === load.id
                    ? 'bg-[#d946ef]/20 border-[#d946ef]/50'
                    : 'bg-white/5 border-white/10 hover:border-[#d946ef]/50'
                }`}
              >
                <p className="font-semibold text-sm mb-1">{load.reference}</p>
                <p className="text-xs text-gray-400 mb-2">{load.driver}</p>
                <div className="flex justify-between items-center text-xs">
                  <span className="text-gray-500">{load.progress}% progress</span>
                  <span className="text-blue-400">{load.speed} mph</span>
                </div>
              </button>
            ))}
          </div>

          {/* VEHICLE STATUS */}
          {selectedLoadData && (
            <>
              <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
                <h3 className="font-bold mb-4">Vehicle Status</h3>

                <div className="space-y-3">
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-400">Plate</span>
                    <span className="font-semibold">{selectedLoadData.plate}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-400">Temperature</span>
                    <span className="font-semibold">{selectedLoadData.temperature}°F</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-gray-400">Fuel Level</span>
                    <div className="flex items-center gap-2">
                      <div className="w-16 bg-white/10 rounded-full h-1.5 overflow-hidden">
                        <div
                          className="bg-gradient-to-r from-green-500 to-green-400 h-full"
                          style={{ width: `${selectedLoadData.fuel}%` }}
                        ></div>
                      </div>
                      <span className="font-semibold text-sm">{selectedLoadData.fuel}%</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* ROUTE DETAILS */}
              <div className="bg-gradient-to-br from-[#1a1a2e] to-[#16213e] rounded-xl border border-white/10 p-6 space-y-4">
                <h3 className="font-bold mb-4">Route Details</h3>

                <div className="space-y-3">
                  <div>
                    <p className="text-xs text-gray-500 mb-1">Total Distance</p>
                    <p className="font-semibold">{selectedLoadData.distance}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500 mb-1">Remaining</p>
                    <p className="font-semibold text-orange-400">{selectedLoadData.remaining}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-500 mb-1">Estimated Arrival</p>
                    <p className="font-semibold">{selectedLoadData.eta}</p>
                  </div>
                </div>
              </div>
            </>
          )}

          {/* ALERT BUTTON */}
          <button className="w-full py-3 px-4 rounded-lg bg-red-600/20 hover:bg-red-600/30 text-red-400 font-semibold transition-colors border border-red-600/50">
            🚨 Alert Driver
          </button>
        </div>
      </div>
    </div>
  )
}

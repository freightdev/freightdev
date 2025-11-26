'use client'

import { ReactNode } from 'react'

export function PortalLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-[#0f001c] text-white px-6 py-10">
      {/* Client portal sidebar or dashboard header goes here */}
      {children}
    </div>
  )
}

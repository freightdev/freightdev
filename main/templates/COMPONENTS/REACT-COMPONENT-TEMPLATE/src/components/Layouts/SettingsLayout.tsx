'use client'

import { ReactNode } from 'react'

export function SettingsLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen p-10 text-white bg-black">
      {/* Settings sidebar goes here */}
      {children}
    </div>
  )
}

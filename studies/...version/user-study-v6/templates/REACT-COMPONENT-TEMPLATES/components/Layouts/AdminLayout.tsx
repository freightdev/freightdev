'use client'

import { ReactNode } from 'react'

export function AdminLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen px-6 py-8 text-white bg-zinc-900">
      {/* Admin control bar or user switcher goes here */}
      {children}
    </div>
  )
}

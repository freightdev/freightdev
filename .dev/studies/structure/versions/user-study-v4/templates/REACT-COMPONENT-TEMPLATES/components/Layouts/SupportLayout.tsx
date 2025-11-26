'use client'

import { ReactNode } from 'react'

export function SupportLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen p-8 text-white bg-neutral-950">
      {/* Support nav / tabs go here */}
      {children}
    </div>
  )
}

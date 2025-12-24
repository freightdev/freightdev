'use client'

import { ReactNode } from 'react'

export function DashboardLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-[rgb(var(--color-background))] text-[rgb(var(--color-foreground))] px-6 py-10">
      {/* Dashboard sidebar or topbar goes here */}
      {children}
    </div>
  )
}

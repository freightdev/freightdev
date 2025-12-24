'use client'

import { ReactNode } from 'react'

export function ProfileLayout({ children }: { children: ReactNode }) {
  return (
    <main className="w-full min-h-screen px-4 py-8 bg-background text-foreground">
      <section className="max-w-6xl mx-auto space-y-8">
        {/* Profile-specific nav or header could go here */}
        {children}
      </section>
    </main>
  )
}

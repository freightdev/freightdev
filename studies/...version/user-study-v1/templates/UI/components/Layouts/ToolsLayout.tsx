'use client'

import { ReactNode } from 'react'

export function ToolsLayout({ children }: { children: ReactNode }) {
  return (
    <main className="w-full min-h-screen px-4 py-8 bg-background text-foreground">
      <section className="max-w-6xl mx-auto space-y-8">
        {/* Tools navigation or header section could go here */}
        {children}
      </section>
    </main>
  )
}

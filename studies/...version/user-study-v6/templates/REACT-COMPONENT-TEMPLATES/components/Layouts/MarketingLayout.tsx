'use client'

import { ReactNode } from 'react'

export function MarketingLayout({ children }: { children: ReactNode }) {
  return (
    <>
      <main className="flex flex-col items-center justify-center overflow-x-hidden">
        {children}
      </main>
    </>
  )
}

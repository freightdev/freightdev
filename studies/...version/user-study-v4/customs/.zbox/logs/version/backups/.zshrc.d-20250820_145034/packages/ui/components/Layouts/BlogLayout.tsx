'use client'

import { ReactNode } from 'react'

export function BlogLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen px-6 py-12 text-black bg-white">
      {/* Blog header/nav goes here */}
      {children}
    </div>
  )
}

'use client'

import { ReactNode } from 'react'

export function DocsLayout({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen bg-[#0b0014] text-white px-8 py-12">
      {/* Docs sidebar / TOC goes here */}
      {children}
    </div>
  )
}

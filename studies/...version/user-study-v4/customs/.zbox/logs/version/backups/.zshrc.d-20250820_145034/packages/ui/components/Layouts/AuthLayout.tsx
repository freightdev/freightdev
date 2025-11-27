'use client'

import { ReactNode } from 'react'

export function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex items-center justify-center w-full min-h-screen px-6 py-12 text-white bg-black">
      <div className="w-full max-w-md p-8 border shadow-xl bg-white/5 border-white/10 rounded-xl">
        {children}
      </div>
    </div>
  )
}

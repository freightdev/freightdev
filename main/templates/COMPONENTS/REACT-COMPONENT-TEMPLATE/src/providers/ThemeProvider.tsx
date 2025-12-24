'use client'

import '@ui/styles/global.css'
import { ReactNode, useEffect } from 'react'

export function ThemeProvider({ children }: { children: ReactNode }) {
  useEffect(() => {
    document.documentElement.classList.add('dark')
  }, [])

  return (
    <div className="min-h-screen font-sans antialiased motion-safe:transition-colors duration-300 bg-[rgb(var(--color-background))] text-[rgb(var(--color-foreground))]">
      {children}
    </div>
  )
}

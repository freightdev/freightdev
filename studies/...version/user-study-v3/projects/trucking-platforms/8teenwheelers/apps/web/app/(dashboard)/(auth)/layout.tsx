import '@ui/styles/globals.css'

import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'OpenHWY Platform',
  description: 'Just works layout for testing',
}

export default function PlatformLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="h-full text-gray-900 bg-gray-100">
      <body className="h-full">{children}</body>
    </html>
  )
}

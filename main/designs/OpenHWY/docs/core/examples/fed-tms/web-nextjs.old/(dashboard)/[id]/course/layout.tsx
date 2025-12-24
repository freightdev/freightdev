import '@ui/styles/globals.css'

import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'OpenHWY AI Trucking Services',
  description: 'Just works layout for testing',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="h-full text-gray-900 bg-gray-100">
      <body className="h-full">{children}</body>
    </html>
  )
}

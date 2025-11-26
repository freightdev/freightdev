import type { Metadata } from 'next'
import { AuthProvider } from '@/lib/contexts/AuthContext'
import { ToastProvider } from '@/lib/contexts/ToastContext'
import '../styles/globals.css'

export const metadata: Metadata = {
  title: 'FED-TMS | Transportation Management System',
  description: 'Fast & Easy Dispatching - Complete TMS Platform',
  viewport: 'width=device-width, initial-scale=1',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <link rel="icon" href="/favicon.ico" />
      </head>
      <body>
        <AuthProvider>
          <ToastProvider>
            {children}
          </ToastProvider>
        </AuthProvider>
      </body>
    </html>
  )
}

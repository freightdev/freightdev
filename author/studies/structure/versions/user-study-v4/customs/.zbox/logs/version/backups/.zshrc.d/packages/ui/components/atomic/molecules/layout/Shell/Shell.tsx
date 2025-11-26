'use client'

import { useLayout } from '@ui/contexts'
import { LayoutMode } from '@ui/enums'
import { cn } from '@ui/shared/utils'
import type { LayoutProps } from '@ui/types'

export function Shell({ children }: LayoutProps) {
  const { variant } = useLayout()

  return (
    <div
      className={cn(
        'transition-all min-h-screen p-6',
        variant === LayoutMode.Centered && 'flex items-center justify-center text-center',
        variant === LayoutMode.Sidebar && 'pl-64 bg-muted/30',
        variant === LayoutMode.Full && 'p-0'
      )}
    >
      {children}
    </div>
  )
}

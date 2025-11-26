'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface SeparatorProps extends React.HTMLAttributes<HTMLDivElement> {
  orientation?: 'horizontal' | 'vertical'
}

export const Separator = React.forwardRef<HTMLDivElement, SeparatorProps>(
  ({ className, orientation = 'horizontal', ...props }, ref) => {
    return (
      <div
        ref={ref}
        role="separator"
        className={cn(
          'bg-border',
          orientation === 'horizontal' ? 'h-px w-full' : 'h-full w-px',
          className
        )}
        {...props}
      />
    )
  }
)

Separator.displayName = 'Separator'

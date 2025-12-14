'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {}

export const Badge = React.forwardRef<HTMLSpanElement, BadgeProps>(
  ({ className, ...props }, ref) => {
    return (
      <span
        ref={ref}
        className={cn('inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold bg-muted text-foreground', className)}
        {...props}
      />
    )
  }
)

Badge.displayName = 'Badge'

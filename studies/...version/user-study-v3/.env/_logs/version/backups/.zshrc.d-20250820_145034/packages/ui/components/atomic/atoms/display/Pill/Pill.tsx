'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface PillProps extends React.HTMLAttributes<HTMLDivElement> {}

export const Pill = React.forwardRef<HTMLDivElement, PillProps>(
  ({ className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('inline-flex items-center rounded-full border px-3 py-0.5 text-sm font-medium', className)}
        {...props}
      />
    )
  }
)

Pill.displayName = 'Pill'

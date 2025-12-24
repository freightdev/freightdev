'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface ProgressBarProps extends React.HTMLAttributes<HTMLDivElement> {
  value: number
}

export const ProgressBar = React.forwardRef<HTMLDivElement, ProgressBarProps>(
  ({ className, value, ...props }, ref) => {
    return (
      <div
        ref={ref}
        role="progressbar"
        aria-valuenow={value}
        aria-valuemin={0}
        aria-valuemax={100}
        className={cn('relative h-2 w-full overflow-hidden rounded bg-muted', className)}
        {...props}
      >
        <div className="h-full bg-primary" style={{ width: `${value}%` }} />
      </div>
    )
  }
)

ProgressBar.displayName = 'ProgressBar'

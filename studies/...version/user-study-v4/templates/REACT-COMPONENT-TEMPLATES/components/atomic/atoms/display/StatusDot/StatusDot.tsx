'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface StatusDotProps extends React.HTMLAttributes<HTMLSpanElement> {
  status?: 'online' | 'offline' | 'busy' | 'away'
}

const statusColorMap = {
  online: 'bg-green-500',
  offline: 'bg-gray-400',
  busy: 'bg-red-500',
  away: 'bg-yellow-400',
}

export const StatusDot = React.forwardRef<HTMLSpanElement, StatusDotProps>(
  ({ className, status = 'offline', ...props }, ref) => (
    <span
      ref={ref}
      className={cn(
        'inline-block h-2 w-2 rounded-full',
        statusColorMap[status],
        className
      )}
      {...props}
    />
  )
)

StatusDot.displayName = 'StatusDot'

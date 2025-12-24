'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface ErrorProps extends React.HTMLAttributes<HTMLDivElement> {}

export const Error = React.forwardRef<HTMLDivElement, ErrorProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <div
        ref={ref}
        role="alert"
        className={cn('text-sm text-red-600', className)}
        {...props}
      >
        {children}
      </div>
    )
  }
)

Error.displayName = 'Error'

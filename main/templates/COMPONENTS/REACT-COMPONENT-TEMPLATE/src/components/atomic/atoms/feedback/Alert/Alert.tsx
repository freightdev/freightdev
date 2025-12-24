'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface AlertProps extends React.HTMLAttributes<HTMLDivElement> {}

export const Alert = React.forwardRef<HTMLDivElement, AlertProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <div
        ref={ref}
        role="alert"
        className={cn('border-l-4 border-yellow-500 bg-yellow-100 p-4 text-yellow-800', className)}
        {...props}
      >
        {children}
      </div>
    )
  }
)

Alert.displayName = 'Alert'

'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface DividerProps extends React.HTMLAttributes<HTMLHRElement> {}

export const Divider = React.forwardRef<HTMLHRElement, DividerProps>(
  ({ className, ...props }, ref) => {
    return (
      <hr
        ref={ref}
        className={cn('my-4 border-t border-border', className)}
        {...props}
      />
    )
  }
)

Divider.displayName = 'Divider'

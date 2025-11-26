'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface LabelProps extends React.LabelHTMLAttributes<HTMLLabelElement> {}

export const Label = React.forwardRef<HTMLLabelElement, LabelProps>(
  ({ className, ...props }, ref) => {
    return (
      <label
        ref={ref}
        className={cn('text-sm font-medium text-foreground', className)}
        {...props}
      />
    )
  }
)

Label.displayName = 'Label'

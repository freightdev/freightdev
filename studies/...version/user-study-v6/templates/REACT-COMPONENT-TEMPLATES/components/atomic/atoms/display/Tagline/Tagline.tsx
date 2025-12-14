'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface TaglineProps extends React.HTMLAttributes<HTMLParagraphElement> {}

export const Tagline = React.forwardRef<HTMLParagraphElement, TaglineProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <p
        ref={ref}
        className={cn('text-sm text-muted tracking-wide uppercase', className)}
        {...props}
      >
        {children}
      </p>
    )
  }
)

Tagline.displayName = 'Tagline'

'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface TextProps extends React.HTMLAttributes<HTMLParagraphElement> {}

export const Text = React.forwardRef<HTMLParagraphElement, TextProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <p
        ref={ref}
        className={cn('text-base text-foreground', className)}
        {...props}
      >
        {children}
      </p>
    )
  }
)

Text.displayName = 'Text'

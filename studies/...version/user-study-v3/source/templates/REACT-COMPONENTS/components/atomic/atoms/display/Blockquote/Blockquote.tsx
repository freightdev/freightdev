'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface BlockquoteProps extends React.HTMLAttributes<HTMLQuoteElement> {}

export const Blockquote = React.forwardRef<HTMLQuoteElement, BlockquoteProps>(
  ({ className, children, ...props }, ref) => (
    <blockquote
      ref={ref}
      className={cn('border-l-4 border-muted pl-4 italic text-muted-foreground', className)}
      {...props}
    >
      {children}
    </blockquote>
  )
)

Blockquote.displayName = 'Blockquote'

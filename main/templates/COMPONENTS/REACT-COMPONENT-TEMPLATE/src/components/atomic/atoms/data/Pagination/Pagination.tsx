'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface PaginationProps extends React.HTMLAttributes<HTMLDivElement> {}

export const Pagination = React.forwardRef<HTMLDivElement, PaginationProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <nav
        ref={ref}
        role="navigation"
        className={cn('flex items-center justify-center space-x-1 text-sm', className)}
        {...props}
      >
        {children}
      </nav>
    )
  }
)

Pagination.displayName = 'Pagination'

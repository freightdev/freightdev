'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface IconProps extends React.SVGProps<SVGSVGElement> {}

export const Icon = React.forwardRef<SVGSVGElement, IconProps>(
  ({ className, children, ...props }, ref) => (
    <svg
      ref={ref}
      className={cn('w-5 h-5', className)}
      fill="currentColor"
      aria-hidden="true"
      {...props}
    >
      {children}
    </svg>
  )
)

Icon.displayName = 'Icon'

'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface LogoProps extends React.HTMLAttributes<HTMLDivElement> {}

export const Logo = React.forwardRef<HTMLDivElement, LogoProps>(
  ({ className, children = 'LOGO', ...props }, ref) => (
    <div ref={ref} className={cn('text-xl font-bold', className)} {...props}>
      {children}
    </div>
  )
)

Logo.displayName = 'Logo'

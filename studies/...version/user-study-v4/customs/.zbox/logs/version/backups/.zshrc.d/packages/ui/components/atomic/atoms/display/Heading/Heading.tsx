'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface HeadingProps extends React.HTMLAttributes<HTMLHeadingElement> {
  level?: 1 | 2 | 3 | 4 | 5 | 6
}

export const Heading = React.forwardRef<HTMLHeadingElement, HeadingProps>(
  ({ level = 2, className, children, ...props }, ref) => {
    const Tag = `h${level}` as keyof JSX.IntrinsicElements

    return React.createElement(
      Tag,
      {
        ref,
        className: cn('font-bold leading-tight tracking-tight', className),
        ...props,
      },
      children
    )
  }
)

Heading.displayName = 'Heading'

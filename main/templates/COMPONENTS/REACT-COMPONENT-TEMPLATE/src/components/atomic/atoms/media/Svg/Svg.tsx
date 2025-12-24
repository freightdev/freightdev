'use client'

import * as React from 'react'

export interface SvgProps extends React.SVGProps<SVGSVGElement> {}

export const Svg = React.forwardRef<SVGSVGElement, SvgProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <svg
        ref={ref}
        className={className}
        {...props}
      >
        {children}
      </svg>
    )
  }
)

Svg.displayName = 'Svg'

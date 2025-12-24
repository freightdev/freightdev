'use client'

import * as React from 'react'

export interface LegendProps extends React.HTMLAttributes<HTMLLegendElement> {}

export const Legend = React.forwardRef<HTMLLegendElement, LegendProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <legend
        ref={ref}
        className={className}
        {...props}
      >
        {children}
      </legend>
    )
  }
)

Legend.displayName = 'Legend'

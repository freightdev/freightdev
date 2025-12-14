'use client'

import * as React from 'react'

export interface OutputProps extends React.OutputHTMLAttributes<HTMLOutputElement> {}

export const Output = React.forwardRef<HTMLOutputElement, OutputProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <output
        ref={ref}
        className={className}
        {...props}
      >
        {children}
      </output>
    )
  }
)

Output.displayName = 'Output'

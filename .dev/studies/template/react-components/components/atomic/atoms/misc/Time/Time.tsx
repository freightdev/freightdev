'use client'

import * as React from 'react'

export interface TimeProps extends React.TimeHTMLAttributes<HTMLTimeElement> {}

export const Time = React.forwardRef<HTMLTimeElement, TimeProps>(
  ({ children, ...props }, ref) => {
    return (
      <time ref={ref} {...props}>
        {children}
      </time>
    )
  }
)

Time.displayName = 'Time'

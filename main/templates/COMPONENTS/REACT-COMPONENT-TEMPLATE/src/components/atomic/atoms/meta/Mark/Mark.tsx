'use client'

import * as React from 'react'

export interface MarkProps extends React.HTMLAttributes<HTMLElement> {}

export const Mark = React.forwardRef<HTMLElement, MarkProps>(
  ({ className, ...props }, ref) => {
    return (
      <mark
        ref={ref}
        className={className}
        {...props}
      />
    )
  }
)

Mark.displayName = 'Mark'

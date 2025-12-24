'use client'

import * as React from 'react'

export interface BaseProps extends React.BaseHTMLAttributes<HTMLBaseElement> {}

export const Base = React.forwardRef<HTMLBaseElement, BaseProps>(
  ({ ...props }, ref) => {
    return (
      <base
        ref={ref}
        {...props}
      />
    )
  }
)

Base.displayName = 'Base'

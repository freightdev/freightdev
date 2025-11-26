'use client'

import * as React from 'react'

export interface MainProps extends React.HTMLAttributes<HTMLElement> {}

export const Main = React.forwardRef<HTMLElement, MainProps>(
  ({ children, ...props }, ref) => {
    return (
      <main ref={ref} {...props}>
        {children}
      </main>
    )
  }
)

Main.displayName = 'Main'

'use client'

import * as React from 'react'

export interface NavProps extends React.HTMLAttributes<HTMLElement> {}

export const Nav = React.forwardRef<HTMLElement, NavProps>(
  ({ children, ...props }, ref) => {
    return (
      <nav ref={ref} {...props}>
        {children}
      </nav>
    )
  }
)

Nav.displayName = 'Nav'

'use client'

import * as React from 'react'

export interface HeaderProps extends React.HTMLAttributes<HTMLElement> {}

export const Header = React.forwardRef<HTMLElement, HeaderProps>(
  ({ children, ...props }, ref) => {
    return (
      <header ref={ref} {...props}>
        {children}
      </header>
    )
  }
)

Header.displayName = 'Header'

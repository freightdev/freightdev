'use client'

import * as React from 'react'

export interface FooterProps extends React.HTMLAttributes<HTMLElement> {}

export const Footer = React.forwardRef<HTMLElement, FooterProps>(
  ({ children, ...props }, ref) => {
    return (
      <footer ref={ref} {...props}>
        {children}
      </footer>
    )
  }
)

Footer.displayName = 'Footer'

'use client'

import * as React from 'react'

export interface LinkProps extends React.AnchorHTMLAttributes<HTMLAnchorElement> {}

export const Link = React.forwardRef<HTMLAnchorElement, LinkProps>(
  ({ children, ...props }, ref) => {
    return (
      <a ref={ref} {...props}>
        {children}
      </a>
    )
  }
)

Link.displayName = 'Link'

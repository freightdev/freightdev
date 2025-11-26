'use client'

import * as React from 'react'

export interface MenuProps extends React.HTMLAttributes<HTMLElement> {}

export const Menu = React.forwardRef<HTMLElement, MenuProps>(
  ({ children, ...props }, ref) => {
    return (
      <menu ref={ref} {...props}>
        {children}
      </menu>
    )
  }
)

Menu.displayName = 'Menu'

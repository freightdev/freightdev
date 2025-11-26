'use client'

import * as React from 'react'

export interface KeyboardProps extends React.HTMLAttributes<HTMLElement> {}

export const Keyboard = React.forwardRef<HTMLElement, KeyboardProps>(
  ({ children, ...props }, ref) => {
    return (
      <kbd ref={ref} {...props}>
        {children}
      </kbd>
    )
  }
)

Keyboard.displayName = 'Keyboard'

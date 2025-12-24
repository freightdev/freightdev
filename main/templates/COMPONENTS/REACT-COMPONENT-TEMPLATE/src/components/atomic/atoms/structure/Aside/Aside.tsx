'use client'

import * as React from 'react'

export interface AsideProps extends React.HTMLAttributes<HTMLElement> {}

export const Aside = React.forwardRef<HTMLElement, AsideProps>(
  ({ children, ...props }, ref) => {
    return (
      <aside ref={ref} {...props}>
        {children}
      </aside>
    )
  }
)

Aside.displayName = 'Aside'

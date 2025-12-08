'use client'

import * as React from 'react'

export interface FigcaptionProps extends React.HTMLAttributes<HTMLElement> {}

export const Figcaption = React.forwardRef<HTMLElement, FigcaptionProps>(
  ({ children, ...props }, ref) => {
    return (
      <figcaption ref={ref} {...props}>
        {children}
      </figcaption>
    )
  }
)

Figcaption.displayName = 'Figcaption'

'use client'

import * as React from 'react'

export interface FigureProps extends React.HTMLAttributes<HTMLElement> {}

export const Figure = React.forwardRef<HTMLElement, FigureProps>(
  ({ children, ...props }, ref) => {
    return (
      <figure ref={ref} {...props}>
        {children}
      </figure>
    )
  }
)

Figure.displayName = 'Figure'

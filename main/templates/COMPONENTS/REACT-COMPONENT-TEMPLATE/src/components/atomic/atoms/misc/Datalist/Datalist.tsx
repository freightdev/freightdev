'use client'

import * as React from 'react'

export interface DatalistProps extends React.HTMLAttributes<HTMLDataListElement> {}

export const Datalist = React.forwardRef<HTMLDataListElement, DatalistProps>(
  ({ children, ...props }, ref) => {
    return (
      <datalist ref={ref} {...props}>
        {children}
      </datalist>
    )
  }
)

Datalist.displayName = 'Datalist'

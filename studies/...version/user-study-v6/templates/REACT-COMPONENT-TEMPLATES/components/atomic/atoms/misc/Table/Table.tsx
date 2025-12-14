'use client'

import * as React from 'react'

export interface TableProps extends React.TableHTMLAttributes<HTMLTableElement> {}

export const Table = React.forwardRef<HTMLTableElement, TableProps>(
  ({ children, ...props }, ref) => {
    return (
      <table ref={ref} {...props}>
        {children}
      </table>
    )
  }
)

Table.displayName = 'Table'

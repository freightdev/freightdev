'use client'

import * as React from 'react'

export interface SearchProps extends React.InputHTMLAttributes<HTMLInputElement> {}

export const Search = React.forwardRef<HTMLInputElement, SearchProps>(
  ({ className, ...props }, ref) => {
    return (
      <input
        ref={ref}
        type="search"
        className={className}
        {...props}
      />
    )
  }
)

Search.displayName = 'Search'

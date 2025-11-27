'use client'

import * as React from 'react'

export interface TitleProps extends React.HTMLAttributes<HTMLTitleElement> {}

export const Title = React.forwardRef<HTMLTitleElement, TitleProps>(
  ({ children, ...props }, ref) => {
    return (
      <title
        ref={ref}
        {...props}
      >
        {children}
      </title>
    )
  }
)

Title.displayName = 'Title'

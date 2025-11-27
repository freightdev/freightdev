'use client'

import * as React from 'react'

export interface TextHighlightProps extends React.HTMLAttributes<HTMLElement> {}

export const TextHighlight = React.forwardRef<HTMLElement, TextHighlightProps>(
  ({ children, ...props }, ref) => {
    return (
      <mark ref={ref} {...props}>
        {children}
      </mark>
    )
  }
)

TextHighlight.displayName = 'TextHighlight'

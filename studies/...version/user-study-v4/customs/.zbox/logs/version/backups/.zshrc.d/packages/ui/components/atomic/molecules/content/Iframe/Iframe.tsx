'use client'

import * as React from 'react'

export interface IframeProps extends React.IframeHTMLAttributes<HTMLIFrameElement> {}

export const Iframe = React.forwardRef<HTMLIFrameElement, IframeProps>(
  ({ className, ...props }, ref) => {
    return (
      <iframe
        ref={ref}
        className={className}
        {...props}
      />
    )
  }
)

Iframe.displayName = 'Iframe'

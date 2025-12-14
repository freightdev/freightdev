'use client'

import * as React from 'react'

export interface PictureProps extends React.HTMLAttributes<HTMLPictureElement> {}

export const Picture = React.forwardRef<HTMLPictureElement, PictureProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <picture
        ref={ref}
        className={className}
        {...props}
      >
        {children}
      </picture>
    )
  }
)

Picture.displayName = 'Picture'

'use client'

import * as React from 'react'

export interface ImgProps extends React.ImgHTMLAttributes<HTMLImageElement> {}

export const Img = React.forwardRef<HTMLImageElement, ImgProps>(
  ({ className, ...props }, ref) => {
    return (
      <img
        ref={ref}
        className={className}
        {...props}
      />
    )
  }
)

Img.displayName = 'Img'

'use client'

import * as React from 'react'

export interface CanvasProps extends React.CanvasHTMLAttributes<HTMLCanvasElement> {}

export const Canvas = React.forwardRef<HTMLCanvasElement, CanvasProps>(
  ({ className, ...props }, ref) => {
    return (
      <canvas
        ref={ref}
        className={className}
        {...props}
      />
    )
  }
)

Canvas.displayName = 'Canvas'

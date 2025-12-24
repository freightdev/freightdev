'use client'

import * as React from 'react'

export interface VideoProps extends React.VideoHTMLAttributes<HTMLVideoElement> {}

export const Video = React.forwardRef<HTMLVideoElement, VideoProps>(
  ({ className, ...props }, ref) => {
    return (
      <video
        ref={ref}
        className={className}
        {...props}
      />
    )
  }
)

Video.displayName = 'Video'

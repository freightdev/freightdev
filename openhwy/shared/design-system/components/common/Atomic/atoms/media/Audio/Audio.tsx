'use client'

import * as React from 'react'

export interface AudioProps extends React.AudioHTMLAttributes<HTMLAudioElement> {}

export const Audio = React.forwardRef<HTMLAudioElement, AudioProps>(
  ({ className, ...props }, ref) => {
    return (
      <audio
        ref={ref}
        className={className}
        {...props}
      />
    )
  }
)

Audio.displayName = 'Audio'

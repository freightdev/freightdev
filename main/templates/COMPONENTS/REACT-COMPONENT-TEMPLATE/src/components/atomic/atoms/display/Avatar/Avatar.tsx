'use client'

import { cn } from '@ui/shared/utils'
import * as React from 'react'

export interface AvatarProps extends React.ImgHTMLAttributes<HTMLImageElement> {}

export const Avatar = React.forwardRef<HTMLImageElement, AvatarProps>(
  ({ className, ...props }, ref) => (
    <img
      ref={ref}
      className={cn('h-10 w-10 rounded-full object-cover', className)}
      {...props}
    />
  )
)

Avatar.displayName = 'Avatar'

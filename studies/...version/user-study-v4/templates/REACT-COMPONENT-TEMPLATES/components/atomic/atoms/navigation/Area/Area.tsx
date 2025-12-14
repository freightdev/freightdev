'use client'

import * as React from 'react'

export interface AreaProps extends React.AreaHTMLAttributes<HTMLAreaElement> {}

export const Area = React.forwardRef<HTMLAreaElement, AreaProps>(
  ({ ...props }, ref) => {
    return <area ref={ref} {...props} />
  }
)

Area.displayName = 'Area'

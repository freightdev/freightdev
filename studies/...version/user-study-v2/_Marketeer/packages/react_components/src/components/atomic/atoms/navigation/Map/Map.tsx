'use client'

import * as React from 'react'

export interface MapProps extends React.MapHTMLAttributes<HTMLMapElement> {}

export const Map = React.forwardRef<HTMLMapElement, MapProps>(
  ({ children, ...props }, ref) => {
    return (
      <map ref={ref} {...props}>
        {children}
      </map>
    )
  }
)

Map.displayName = 'Map'

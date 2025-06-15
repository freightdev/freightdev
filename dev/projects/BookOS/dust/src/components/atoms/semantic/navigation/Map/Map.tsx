'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  MapBorder,
  MapRadius,
  MapSize,
} from './Map.props'
import { mapVariants } from './Map.variants'

export type MapProps<T extends React.ElementType = 'map'> = {
  size?: MapSize
  border?: MapBorder
  radius?: MapRadius
  as?: T
  className?: string
  children?: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function MapInner(props: MapProps, ref: React.Ref<any>) {
  const {
    size = 'md',
    border = 'none',
    radius = 'none',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'map') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(mapVariants({ size, border, radius }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const MapBase = React.forwardRef(MapInner)
MapBase.displayName = 'Map'

export function Map<T extends React.ElementType = 'map'>(
  props: MapProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <MapBase {...props} />
}

'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  PictureBorder,
  PictureRadius,
  PictureShadow,
} from './Picture.props'
import { pictureVariants } from './Picture.variants'

export type PictureProps<T extends React.ElementType = 'picture'> = {
  radius?: PictureRadius
  shadow?: PictureShadow
  border?: PictureBorder
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function PictureInner(props: PictureProps, ref: React.Ref<any>) {
  const {
    radius = 'none',
    shadow = 'none',
    border = 'none',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'picture') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(pictureVariants({ radius, shadow, border }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const PictureBase = React.forwardRef(PictureInner)
PictureBase.displayName = 'Picture'

export function Picture<T extends React.ElementType = 'picture'>(
  props: PictureProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <PictureBase {...props} />
}

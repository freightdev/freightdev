'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  ImgBorder,
  ImgFit,
  ImgRadius,
  ImgShadow,
} from './Img.props'
import { imgVariants } from './Img.variants'

export type ImgProps<T extends React.ElementType = 'img'> = {
  radius?: ImgRadius
  shadow?: ImgShadow
  border?: ImgBorder
  fit?: ImgFit
  as?: T
  className?: string
} & Omit<React.ComponentPropsWithoutRef<T>, 'as' | 'ref'>

function ImgInner(props: ImgProps, ref: React.Ref<any>) {
  const {
    radius = 'none',
    shadow = 'none',
    border = 'none',
    fit = 'cover',
    as,
    className,
    ...rest
  } = props

  const Component = (as || 'img') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(imgVariants({ radius, shadow, border, fit }), className)}
      {...rest}
    />
  )
}

const ImgBase = React.forwardRef(ImgInner)
ImgBase.displayName = 'Img'

export function Img<T extends React.ElementType = 'img'>(
  props: ImgProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <ImgBase {...props} />
}

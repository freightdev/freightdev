'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  SvgColor,
  SvgSize,
  SvgStroke,
} from './Svg.props'
import { svgVariants } from './Svg.variants'

export type SvgProps<T extends React.ElementType = 'svg'> = {
  size?: SvgSize
  color?: SvgColor
  stroke?: SvgStroke
  as?: T
  className?: string
  children?: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function SvgInner(props: SvgProps, ref: React.Ref<any>) {
  const {
    size = 'md',
    color = 'current',
    stroke = 'default',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'svg') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(svgVariants({ size, color, stroke }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const SvgBase = React.forwardRef(SvgInner)
SvgBase.displayName = 'Svg'

export function Svg<T extends React.ElementType = 'svg'>(
  props: SvgProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <SvgBase {...props} />
}

'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  AreaBg,
  AreaBorder,
  AreaSize,
} from './Area.props'
import { areaVariants } from './Area.variants'

export type AreaProps<T extends React.ElementType = 'div'> = {
  size?: AreaSize
  bg?: AreaBg
  border?: AreaBorder
  as?: T
  className?: string
  children?: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function AreaInner(props: AreaProps, ref: React.Ref<any>) {
  const {
    size = 'md',
    bg = 'none',
    border = 'none',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'div') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(areaVariants({ size, bg, border }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const AreaBase = React.forwardRef(AreaInner)
AreaBase.displayName = 'Area'

export function Area<T extends React.ElementType = 'div'>(
  props: AreaProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <AreaBase {...props} />
}

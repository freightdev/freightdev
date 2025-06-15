'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  MarkColor,
  MarkSize,
  MarkWeight,
} from './Mark.props'
import { markVariants } from './Mark.variants'

export type MarkProps<T extends React.ElementType = 'mark'> = {
  color?: MarkColor
  weight?: MarkWeight
  size?: MarkSize
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function MarkInner(props: MarkProps, ref: React.Ref<any>) {
  const {
    color = 'yellow',
    weight = 'normal',
    size = 'md',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'mark') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(markVariants({ color, weight, size }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const MarkBase = React.forwardRef(MarkInner)
MarkBase.displayName = 'Mark'

export function Mark<T extends React.ElementType = 'mark'>(
  props: MarkProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <MarkBase {...props} />
}

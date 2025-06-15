'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  BaseHref,
  BaseTarget,
} from './Base.props'
import { baseVariants } from './Base.variants'

export type BaseProps<T extends React.ElementType = 'base'> = {
  href?: BaseHref
  target?: BaseTarget
  as?: T
  className?: string
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function BaseInner(props: BaseProps, ref: React.Ref<any>) {
  const {
    href = '/',
    target,
    as,
    className,
    ...rest
  } = props

  const Component = (as || 'base') as React.ElementType

  return (
    <Component
      ref={ref}
      href={href}
      target={target}
      className={cn(baseVariants(), className)}
      {...rest}
    />
  )
}

const BaseBase = React.forwardRef(BaseInner)
BaseBase.displayName = 'Base'

export function Base<T extends React.ElementType = 'base'>(
  props: BaseProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <BaseBase {...props} />
}

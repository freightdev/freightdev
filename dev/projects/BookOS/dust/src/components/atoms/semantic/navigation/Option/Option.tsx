'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  OptionSize,
  OptionState,
  OptionTone,
} from './Option.props'
import { optionVariants } from './Option.variants'

export type OptionProps<T extends React.ElementType = 'option'> = {
  tone?: OptionTone
  size?: OptionSize
  state?: OptionState
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function OptionInner(props: OptionProps, ref: React.Ref<any>) {
  const {
    tone = 'default',
    size = 'md',
    state = 'enabled',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'option') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(optionVariants({ tone, size, state }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const OptionBase = React.forwardRef(OptionInner)
OptionBase.displayName = 'Option'

export function Option<T extends React.ElementType = 'option'>(
  props: OptionProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <OptionBase {...props} />
}

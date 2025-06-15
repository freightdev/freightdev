'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  PillRounded,
  PillSize,
  PillStyle,
  PillTone,
  PillWeight,
} from './Pill.props'
import { pillVariants } from './Pill.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type PillProps<T extends React.ElementType = 'span'> = PolymorphicProps<
  T,
  {
    tone?: PillTone
    size?: PillSize
    weight?: PillWeight
    rounded?: PillRounded
    style?: PillStyle
    className?: string
  }
>

export const Pill = React.forwardRef(
  <T extends React.ElementType = 'span'>(
    {
      as,
      tone = 'default',
      size = 'md',
      weight = 'medium',
      rounded = 'full',
      style = 'solid',
      className,
      children,
      ...props
    }: PillProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'span') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(pillVariants({ tone, size, weight, rounded, style }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'span', PillProps>

Pill.displayName = 'Pill'

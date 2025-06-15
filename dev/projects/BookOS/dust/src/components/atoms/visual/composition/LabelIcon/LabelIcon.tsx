'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  LabelIconGap,
  LabelIconSize,
  LabelIconTone,
  LabelIconWeight,
} from './LabelIcon.props'
import { labelIconVariants } from './LabelIcon.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type LabelIconProps<T extends React.ElementType = 'span'> = PolymorphicProps<
  T,
  {
    size?: LabelIconSize
    tone?: LabelIconTone
    weight?: LabelIconWeight
    gap?: LabelIconGap
    className?: string
  }
>

export const LabelIcon = React.forwardRef(
  <T extends React.ElementType = 'span'>(
    {
      as,
      size = 'md',
      tone = 'default',
      weight = 'medium',
      gap = 'sm',
      className,
      children,
      ...props
    }: LabelIconProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'span') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(labelIconVariants({ size, tone, weight, gap }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'span', LabelIconProps>

LabelIcon.displayName = 'LabelIcon'

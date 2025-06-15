'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { LegendSize, LegendTone } from './Legend.props'
import { legendVariants } from './Legend.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type LegendProps<T extends React.ElementType = 'legend'> = PolymorphicProps<
  T,
  {
    size?: LegendSize
    tone?: LegendTone
    className?: string
  }
>

export const Legend = React.forwardRef(
  <T extends React.ElementType = 'legend'>(
    {
      as,
      size = 'md',
      tone = 'default',
      className,
      children,
      ...props
    }: LegendProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'legend') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(legendVariants({ tone, size }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'legend', LegendProps>

Legend.displayName = 'Legend'

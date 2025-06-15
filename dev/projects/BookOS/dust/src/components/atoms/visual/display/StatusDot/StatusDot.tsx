'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  StatusDotGlow,
  StatusDotSize,
  StatusDotTone,
} from './StatusDot.props'
import { statusDotVariants } from './StatusDot.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type StatusDotProps<T extends React.ElementType = 'span'> = PolymorphicProps<
  T,
  {
    size?: StatusDotSize
    tone?: StatusDotTone
    glow?: StatusDotGlow
    className?: string
  }
>

export const StatusDot = React.forwardRef(
  <T extends React.ElementType = 'span'>(
    {
      as,
      size = 'sm',
      tone = 'neutral',
      glow = false,
      className,
      ...props
    }: StatusDotProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'span') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(statusDotVariants({ size, tone, glow }), className)}
        {...props}
      />
    )
  }
) as PolymorphicComponentWithRef<'span', StatusDotProps>

StatusDot.displayName = 'StatusDot'

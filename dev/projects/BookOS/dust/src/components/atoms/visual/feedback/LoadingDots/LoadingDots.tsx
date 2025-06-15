'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { LoadingDotsSize, LoadingDotsTone } from './LoadingDots.props'
import { loadingDotsVariants } from './LoadingDots.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type LoadingDotsProps<T extends React.ElementType = 'span'> = PolymorphicProps<
  T,
  {
    size?: LoadingDotsSize
    tone?: LoadingDotsTone
    count?: number
    className?: string
  }
>

export const LoadingDots = React.forwardRef(
  <T extends React.ElementType = 'span'>(
    {
      as,
      size = 'md',
      tone = 'default',
      count = 3,
      className,
      ...props
    }: LoadingDotsProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'span') as React.ElementType
    const dotClass = cn(
      loadingDotsVariants({ size, tone }),
      'rounded-full animate-pulse'
    )

    return (
      <Component ref={ref} className={cn('flex gap-1 items-center', className)} {...props}>
        {Array.from({ length: count }).map((_, i) => (
          <span key={i} className={cn(dotClass, `delay-[${i * 150}ms]`)} />
        ))}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'span', LoadingDotsProps>

LoadingDots.displayName = 'LoadingDots'

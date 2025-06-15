'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { SkeletonShape, SkeletonSize } from './Skeleton.props'
import { skeletonVariants } from './Skeleton.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type SkeletonProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    size?: SkeletonSize
    shape?: SkeletonShape
    className?: string
  }
>

export const Skeleton = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    { as, size = 'md', shape = 'square', className, ...props }: SkeletonProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(skeletonVariants({ size, shape }), className)}
        {...props}
      />
    )
  }
) as PolymorphicComponentWithRef<'div', SkeletonProps>

Skeleton.displayName = 'Skeleton'

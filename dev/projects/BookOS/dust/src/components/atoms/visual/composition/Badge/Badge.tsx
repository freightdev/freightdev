'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { BadgeVariant } from './Badge.props'
import { badgeVariants } from './Badge.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type BadgeProps<T extends React.ElementType = 'span'> = PolymorphicProps<
  T,
  {
    variant?: BadgeVariant
    className?: string
  }
>

export const Badge = React.forwardRef(
  <T extends React.ElementType = 'span'>(
    { as, className, variant = 'default', children, ...props }: BadgeProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'span') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(badgeVariants({ variant }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'span', BadgeProps>

Badge.displayName = 'Badge'

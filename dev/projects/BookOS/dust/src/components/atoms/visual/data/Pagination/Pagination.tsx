'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  PaginationRounded,
  PaginationSize,
  PaginationTone,
} from './Pagination.props'
import { paginationVariants } from './Pagination.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type PaginationProps<T extends React.ElementType = 'button'> = PolymorphicProps<
  T,
  {
    size?: PaginationSize
    tone?: PaginationTone
    rounded?: PaginationRounded
    className?: string
  }
>

export const Pagination = React.forwardRef(
  <T extends React.ElementType = 'button'>(
    {
      as,
      size = 'md',
      tone = 'default',
      rounded = 'md',
      className,
      children,
      ...props
    }: PaginationProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'button') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(paginationVariants({ size, tone, rounded }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'button', PaginationProps>

Pagination.displayName = 'Pagination'

'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  TableBorder,
  TableRounded,
  TableShadow,
  TableTone,
} from './Table.props'
import { tableVariants } from './Table.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type TableProps<T extends React.ElementType = 'table'> = PolymorphicProps<
  T,
  {
    tone?: TableTone
    shadow?: TableShadow
    border?: TableBorder
    rounded?: TableRounded
    className?: string
  }
>

export const Table = React.forwardRef(
  <T extends React.ElementType = 'table'>(
    {
      as,
      tone = 'default',
      shadow = 'none',
      border = 'outer',
      rounded = 'sm',
      className,
      children,
      ...props
    }: TableProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'table') as React.ElementType

    return (
      <div className="overflow-auto w-full">
        <Component
          ref={ref}
          className={cn(tableVariants({ tone, shadow, border, rounded }), className)}
          {...props}
        >
          {children}
        </Component>
      </div>
    )
  }
) as PolymorphicComponentWithRef<'table', TableProps>

Table.displayName = 'Table'

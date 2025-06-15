'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { SelectSize, SelectVariant } from './Select.props'
import { selectVariants } from './Select.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type SelectProps<T extends React.ElementType = 'select'> = PolymorphicProps<
  T,
  {
    size?: SelectSize
    variant?: SelectVariant
    className?: string
    name?: string
    value?: string
    onChange?: (event: React.ChangeEvent<HTMLSelectElement>) => void
  }
>

export const Select = React.forwardRef(
  <T extends React.ElementType = 'select'>(
    {
      as,
      size = 'md',
      variant = 'default',
      className,
      children,
      ...props
    }: SelectProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'select') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(selectVariants({ size, variant }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'select', SelectProps>

Select.displayName = 'Select'

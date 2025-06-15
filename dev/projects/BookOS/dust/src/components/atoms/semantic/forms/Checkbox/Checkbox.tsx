'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { CheckboxSize } from './Checkbox.props'
import { checkboxVariants } from './Checkbox.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type CheckboxProps<T extends React.ElementType = 'input'> = PolymorphicProps<
  T,
  {
    size?: CheckboxSize
    className?: string
    checked?: boolean
    onChange?: (event: React.ChangeEvent<HTMLInputElement>) => void
  }
>

export const Checkbox = React.forwardRef(
  <T extends React.ElementType = 'input'>(
    { as, size = 'md', className, ...props }: CheckboxProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'input') as React.ElementType

    return (
      <Component
        type="checkbox"
        ref={ref}
        className={cn(checkboxVariants({ size }), className)}
        {...props}
      />
    )
  }
) as PolymorphicComponentWithRef<'input', CheckboxProps>

Checkbox.displayName = 'Checkbox'

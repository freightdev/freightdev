'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { InputSize, InputVariant } from './Input.props'
import { inputVariants } from './Input.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type InputProps<T extends React.ElementType = 'input'> = PolymorphicProps<
  T,
  {
    variant?: InputVariant
    size?: InputSize
    className?: string
    type?: string
  }
>

export const Input = React.forwardRef(
  <T extends React.ElementType = 'input'>(
    {
      as,
      type = 'text',
      variant = 'default',
      size = 'md',
      className,
      children,
      ...props
    }: InputProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'input') as React.ElementType

    return (
      <Component
        ref={ref}
        type={type}
        className={cn(inputVariants({ variant, size }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'input', InputProps>

Input.displayName = 'Input'

'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { ButtonSizes, ButtonVariants } from './Button.props'
import { buttonVariants } from './Button.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type ButtonProps<T extends React.ElementType = 'button'> = PolymorphicProps<
  T,
  {
    variant?: ButtonVariants
    size?: ButtonSizes
    className?: string
  }
>

export const Button = React.forwardRef(
  <T extends React.ElementType = 'button'>(
    {
      as,
      className,
      variant = 'default',
      size = 'md',
      children,
      ...props
    }: ButtonProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = as || 'button'

    return (
      <Component
        ref={ref}
        className={cn(buttonVariants({ variant, size }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'button', ButtonProps>


Button.displayName = 'Button'

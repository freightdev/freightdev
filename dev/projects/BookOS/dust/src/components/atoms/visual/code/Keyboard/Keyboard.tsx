'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  KeyboardRounded,
  KeyboardSize,
  KeyboardTone,
} from './Keyboard.props'
import { keyboardVariants } from './Keyboard.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type KeyboardProps<T extends React.ElementType = 'kbd'> = PolymorphicProps<
  T,
  {
    size?: KeyboardSize
    tone?: KeyboardTone
    rounded?: KeyboardRounded
    className?: string
  }
>

export const Keyboard = React.forwardRef(
  <T extends React.ElementType = 'kbd'>(
    {
      as,
      size = 'sm',
      tone = 'default',
      rounded = 'sm',
      className,
      children,
      ...props
    }: KeyboardProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'kbd') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(keyboardVariants({ size, tone, rounded }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'kbd', KeyboardProps>

Keyboard.displayName = 'Keyboard'

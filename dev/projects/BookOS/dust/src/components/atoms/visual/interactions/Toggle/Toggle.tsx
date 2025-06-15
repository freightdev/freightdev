'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  ToggleRounded,
  ToggleSize,
  ToggleTone,
} from './Toggle.props'
import { toggleVariants } from './Toggle.variants'

type AsProp<T extends React.ElementType> = { as?: T }

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type ToggleProps<T extends React.ElementType = 'button'> = PolymorphicProps<
  T,
  {
    tone?: ToggleTone
    size?: ToggleSize
    rounded?: ToggleRounded
    pressed?: boolean
    className?: string
  }
>

export const Toggle = React.forwardRef(
  <T extends React.ElementType = 'button'>(
    {
      as,
      tone = 'default',
      size = 'md',
      rounded = 'md',
      pressed = false,
      className,
      children,
      ...props
    }: ToggleProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'button') as React.ElementType

    return (
      <Component
        ref={ref}
        role="button"
        aria-pressed={pressed}
        data-state={pressed ? 'on' : 'off'}
        className={cn(toggleVariants({ tone, size, rounded }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'button', ToggleProps>

Toggle.displayName = 'Toggle'

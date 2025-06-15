'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  PopoverRounded,
  PopoverShadow,
  PopoverSize,
  PopoverTone,
} from './Popover.props'
import { popoverVariants } from './Popover.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type PopoverProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    size?: PopoverSize
    tone?: PopoverTone
    rounded?: PopoverRounded
    shadow?: PopoverShadow
    className?: string
  }
>

export const Popover = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    {
      as,
      size = 'md',
      tone = 'default',
      rounded = 'md',
      shadow = 'md',
      className,
      children,
      ...props
    }: PopoverProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(popoverVariants({ size, tone, rounded, shadow }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'div', PopoverProps>

Popover.displayName = 'Popover'

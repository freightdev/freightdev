'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  SonnerRounded,
  SonnerShadow,
  SonnerTone,
} from './Sonner.props'
import { sonnerVariants } from './Sonner.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type SonnerProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    tone?: SonnerTone
    shadow?: SonnerShadow
    rounded?: SonnerRounded
    className?: string
  }
>

export const Sonner = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    {
      as,
      tone = 'default',
      shadow = 'md',
      rounded = 'md',
      className,
      children,
      ...props
    }: SonnerProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        role="alert"
        className={cn(sonnerVariants({ tone, shadow, rounded }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'div', SonnerProps>

Sonner.displayName = 'Sonner'

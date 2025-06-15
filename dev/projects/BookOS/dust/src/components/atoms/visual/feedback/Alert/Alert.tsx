'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  AlertRounded,
  AlertShadow,
  AlertTone,
} from './Alert.props'
import { alertVariants } from './Alert.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type AlertProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    tone?: AlertTone
    rounded?: AlertRounded
    shadow?: AlertShadow
    className?: string
  }
>

export const Alert = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    {
      as,
      tone = 'default',
      rounded = 'md',
      shadow = 'none',
      className,
      children,
      ...props
    }: AlertProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        role="alert"
        className={cn(alertVariants({ tone, rounded, shadow }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'div', AlertProps>

Alert.displayName = 'Alert'

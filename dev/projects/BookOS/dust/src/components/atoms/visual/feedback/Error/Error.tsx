'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  ErrorAlign,
  ErrorSize,
  ErrorTone,
} from './Error.props'
import { errorVariants } from './Error.variants'

type AsProp<T extends React.ElementType> = { as?: T }

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type ErrorProps<T extends React.ElementType = 'span'> = PolymorphicProps<
  T,
  {
    tone?: ErrorTone
    size?: ErrorSize
    align?: ErrorAlign
    icon?: React.ReactNode
    className?: string
  }
>

export const Error = React.forwardRef(
  <T extends React.ElementType = 'span'>(
    {
      as,
      tone = 'default',
      size = 'sm',
      align = 'left',
      icon,
      className,
      children,
      ...props
    }: ErrorProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'span') as React.ElementType

    return (
      <Component
        ref={ref}
        role="alert"
        className={cn(errorVariants({ tone, size, align }), className)}
        {...props}
      >
        {icon && <span className="mt-0.5">{icon}</span>}
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'span', ErrorProps>

Error.displayName = 'Error'

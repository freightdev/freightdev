'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { TextareaSize, TextareaVariant } from './Textarea.props'
import { textareaVariants } from './Textarea.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type TextareaProps<T extends React.ElementType = 'textarea'> = PolymorphicProps<
  T,
  {
    variant?: TextareaVariant
    size?: TextareaSize
    className?: string
    rows?: number
    placeholder?: string
  }
>

export const Textarea = React.forwardRef(
  <T extends React.ElementType = 'textarea'>(
    {
      as,
      variant = 'default',
      size = 'md',
      className,
      children,
      ...props
    }: TextareaProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'textarea') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(textareaVariants({ variant, size }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'textarea', TextareaProps>

Textarea.displayName = 'Textarea'

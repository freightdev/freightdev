'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { TextSize, TextTone, TextWeight } from './Text.props'
import { textVariants } from './Text.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type TextProps<T extends React.ElementType = 'span'> = PolymorphicProps<
  T,
  {
    size?: TextSize
    weight?: TextWeight
    tone?: TextTone
    className?: string
  }
>

export const Text = React.forwardRef(
  <T extends React.ElementType = 'span'>(
    {
      as,
      size = 'md',
      weight = 'normal',
      tone = 'default',
      className,
      children,
      ...props
    }: TextProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'span') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(textVariants({ size, weight, tone }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'span', TextProps>

Text.displayName = 'Text'

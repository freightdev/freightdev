'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  TextHighlightSize,
  TextHighlightStyle,
  TextHighlightTone,
  TextHighlightWeight,
} from './TextHighlight.props'
import { textHighlightVariants } from './TextHighlight.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type TextHighlightProps<T extends React.ElementType = 'mark'> = PolymorphicProps<
  T,
  {
    tone?: TextHighlightTone
    size?: TextHighlightSize
    weight?: TextHighlightWeight
    style?: TextHighlightStyle
    className?: string
  }
>

export const TextHighlight = React.forwardRef(
  <T extends React.ElementType = 'mark'>(
    {
      as,
      tone = 'default',
      size = 'md',
      weight = 'medium',
      style = 'solid',
      className,
      children,
      ...props
    }: TextHighlightProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'mark') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(textHighlightVariants({ tone, size, weight, style }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'mark', TextHighlightProps>

TextHighlight.displayName = 'TextHighlight'

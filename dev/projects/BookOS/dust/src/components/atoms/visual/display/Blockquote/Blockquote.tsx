'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  BlockquoteAccent,
  BlockquoteSize,
  BlockquoteTone,
  BlockquoteWeight,
} from './Blockquote.props'
import { blockquoteVariants } from './Blockquote.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type BlockquoteProps<T extends React.ElementType = 'blockquote'> = PolymorphicProps<
  T,
  {
    tone?: BlockquoteTone
    size?: BlockquoteSize
    weight?: BlockquoteWeight
    accent?: BlockquoteAccent
    cite?: string
    className?: string
  }
>

export const Blockquote = React.forwardRef(
  <T extends React.ElementType = 'blockquote'>(
    {
      as,
      tone = 'default',
      size = 'md',
      weight = 'normal',
      accent = 'none',
      cite,
      className,
      children,
      ...props
    }: BlockquoteProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'blockquote') as React.ElementType

    return (
      <Component
        ref={ref}
        cite={cite}
        className={cn(blockquoteVariants({ tone, size, weight, accent }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'blockquote', BlockquoteProps>

Blockquote.displayName = 'Blockquote'

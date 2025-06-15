'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  TaglineAlign,
  TaglineSize,
  TaglineTone,
  TaglineWeight,
} from './Tagline.props'
import { taglineVariants } from './Tagline.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type TaglineProps<T extends React.ElementType = 'span'> = PolymorphicProps<
  T,
  {
    tone?: TaglineTone
    size?: TaglineSize
    weight?: TaglineWeight
    align?: TaglineAlign
    className?: string
  }
>

export const Tagline = React.forwardRef(
  <T extends React.ElementType = 'span'>(
    {
      as,
      tone = 'default',
      size = 'sm',
      weight = 'medium',
      align = 'left',
      className,
      children,
      ...props
    }: TaglineProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'span') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(taglineVariants({ tone, size, weight, align }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'span', TaglineProps>

Tagline.displayName = 'Tagline'

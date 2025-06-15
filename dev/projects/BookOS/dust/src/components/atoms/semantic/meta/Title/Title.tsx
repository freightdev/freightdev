'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  TitleAlign,
  TitleCasing,
  TitleSize,
  TitleTone,
} from './Title.props'
import { titleVariants } from './Title.variants'

type AsProp<T extends React.ElementType> = { as?: T }

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type TitleProps<T extends React.ElementType = 'h1'> = PolymorphicProps<
  T,
  {
    size?: TitleSize
    tone?: TitleTone
    align?: TitleAlign
    casing?: TitleCasing
    className?: string
  }
>

export const Title = React.forwardRef(
  <T extends React.ElementType = 'h1'>(
    {
      as,
      size = 'xl',
      tone = 'default',
      align = 'left',
      casing = 'normal',
      className,
      children,
      ...props
    }: TitleProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'h1') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(titleVariants({ size, tone, align, casing }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'h1', TitleProps>

Title.displayName = 'Title'

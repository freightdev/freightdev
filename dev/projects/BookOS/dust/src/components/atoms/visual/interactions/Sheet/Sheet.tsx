'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  SheetPosition,
  SheetRounded,
  SheetShadow,
  SheetSize,
  SheetTone,
} from './Sheet.props'
import { sheetVariants } from './Sheet.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type SheetProps<T extends React.ElementType = 'aside'> = PolymorphicProps<
  T,
  {
    position?: SheetPosition
    tone?: SheetTone
    size?: SheetSize
    rounded?: SheetRounded
    shadow?: SheetShadow
    className?: string
  }
>

export const Sheet = React.forwardRef(
  <T extends React.ElementType = 'aside'>(
    {
      as,
      position = 'right',
      tone = 'default',
      size = 'md',
      rounded = 'md',
      shadow = 'md',
      className,
      children,
      ...props
    }: SheetProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'aside') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(sheetVariants({ position, tone, size, rounded, shadow }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'aside', SheetProps>

Sheet.displayName = 'Sheet'

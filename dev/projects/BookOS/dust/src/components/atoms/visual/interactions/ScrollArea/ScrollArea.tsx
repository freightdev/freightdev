'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  ScrollAreaRadius,
  ScrollAreaShadow,
  ScrollAreaSize,
  ScrollbarVisibility,
} from './ScrollArea.props'
import { scrollAreaVariants } from './ScrollArea.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type ScrollAreaProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    size?: ScrollAreaSize
    radius?: ScrollAreaRadius
    shadow?: ScrollAreaShadow
    scrollbarVisibility?: ScrollbarVisibility
    className?: string
  }
>

export const ScrollArea = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    {
      as,
      size = 'md',
      radius = 'md',
      shadow = 'none',
      scrollbarVisibility = 'visible',
      className,
      children,
      ...props
    }: ScrollAreaProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(scrollAreaVariants({ size, radius, shadow, scrollbarVisibility }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'div', ScrollAreaProps>

ScrollArea.displayName = 'ScrollArea'

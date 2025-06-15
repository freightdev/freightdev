'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  ResizableBorder,
  ResizableDirection,
  ResizableRounded,
  ResizableShadow,
} from './Resizable.props'
import { resizableVariants } from './Resizable.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type ResizableProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    direction?: ResizableDirection
    border?: ResizableBorder
    shadow?: ResizableShadow
    rounded?: ResizableRounded
    className?: string
  }
>

export const Resizable = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    {
      as,
      direction = 'x',
      border = 'default',
      shadow = 'none',
      rounded = 'md',
      className,
      children,
      ...props
    }: ResizableProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(resizableVariants({ direction, border, shadow, rounded }), className)}
        {...props}
      >
        {children}
        <div
          className={cn(
            'absolute z-10 bg-border hover:bg-primary transition-colors',
            direction === 'x'
              ? 'top-0 right-0 bottom-0 w-1.5 cursor-col-resize'
              : 'left-0 right-0 bottom-0 h-1.5 cursor-row-resize'
          )}
        />
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'div', ResizableProps>

Resizable.displayName = 'Resizable'

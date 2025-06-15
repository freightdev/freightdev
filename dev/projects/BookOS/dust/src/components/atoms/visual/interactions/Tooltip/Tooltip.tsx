'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { TooltipPosition } from './Tooltip.props'
import { tooltipVariants } from './Tooltip.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type TooltipProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    position?: TooltipPosition
    className?: string
  }
>

export const Tooltip = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    { as, position = 'top', className, children, ...props }: TooltipProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        role="tooltip"
        className={cn(tooltipVariants({ position }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'div', TooltipProps>

Tooltip.displayName = 'Tooltip'

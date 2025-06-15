'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  SeparatorDashed,
  SeparatorDirection,
  SeparatorSpacing,
  SeparatorThickness,
  SeparatorTone,
} from './Separator.props'
import { separatorVariants } from './Separator.variants'

type AsProp<T extends React.ElementType> = { as?: T }

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type SeparatorProps<T extends React.ElementType = 'hr'> = PolymorphicProps<
  T,
  {
    direction?: SeparatorDirection
    tone?: SeparatorTone
    thickness?: SeparatorThickness
    spacing?: SeparatorSpacing
    dashed?: SeparatorDashed
    className?: string
  }
>

export const Separator = React.forwardRef(
  <T extends React.ElementType = 'hr'>(
    {
      as,
      direction = 'horizontal',
      tone = 'default',
      thickness = 'md',
      spacing = 'md',
      dashed = false,
      className,
      ...props
    }: SeparatorProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'hr') as React.ElementType

    return (
      <Component
        ref={ref}
        aria-orientation={direction}
        className={cn(
          separatorVariants({ direction, tone, thickness, spacing, dashed }),
          className
        )}
        {...props}
      />
    )
  }
) as PolymorphicComponentWithRef<'hr', SeparatorProps>

Separator.displayName = 'Separator'

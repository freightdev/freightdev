'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  DividerOrientation,
  DividerThickness,
  DividerTone,
} from './Divider.props'
import { dividerVariants } from './Divider.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type DividerProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    orientation?: DividerOrientation
    tone?: DividerTone
    thickness?: DividerThickness
    className?: string
  }
>

export const Divider = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    {
      as,
      orientation = 'horizontal',
      tone = 'default',
      thickness = 'thin',
      className,
      ...props
    }: DividerProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(dividerVariants({ orientation, tone, thickness }), className)}
        {...props}
      />
    )
  }
) as PolymorphicComponentWithRef<'div', DividerProps>

Divider.displayName = 'Divider'

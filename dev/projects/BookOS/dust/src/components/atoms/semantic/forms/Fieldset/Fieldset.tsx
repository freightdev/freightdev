'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  FieldsetBorder,
  FieldsetGap,
  FieldsetPadding
} from './Fieldset.props'
import { fieldsetVariants } from './Fieldset.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type FieldsetProps<T extends React.ElementType = 'fieldset'> = PolymorphicProps<
  T,
  {
    padding?: FieldsetPadding
    border?: FieldsetBorder
    gap?: FieldsetGap
    className?: string
  }
>

export const Fieldset = React.forwardRef(
  <T extends React.ElementType = 'fieldset'>(
    {
      as,
      padding = 'md',
      border = 'subtle',
      gap = 'md',
      className,
      children,
      ...props
    }: FieldsetProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'fieldset') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn('flex flex-col', fieldsetVariants({ padding, border, gap }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'fieldset', FieldsetProps>

Fieldset.displayName = 'Fieldset'

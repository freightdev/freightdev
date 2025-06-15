'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { LabelSize } from './Label.props'
import { labelVariants } from './Label.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type LabelProps<T extends React.ElementType = 'label'> = PolymorphicProps<
  T,
  {
    size?: LabelSize
    htmlFor?: string
    className?: string
  }
>

export const Label = React.forwardRef(
  <T extends React.ElementType = 'label'>(
    { as, size = 'md', htmlFor, className, children, ...props }: LabelProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'label') as React.ElementType

    return (
      <Component
        ref={ref}
        htmlFor={htmlFor}
        className={cn(labelVariants({ size }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'label', LabelProps>

Label.displayName = 'Label'

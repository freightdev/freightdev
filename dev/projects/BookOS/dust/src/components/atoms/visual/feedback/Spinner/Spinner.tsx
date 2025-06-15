'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { SpinnerSize, SpinnerTone } from './Spinner.props'
import { spinnerVariants } from './Spinner.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type SpinnerProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    size?: SpinnerSize
    tone?: SpinnerTone
    className?: string
  }
>

export const Spinner = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    { as, size = 'md', tone = 'default', className, ...props }: SpinnerProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(spinnerVariants({ size, tone }), className)}
        {...props}
      />
    )
  }
) as PolymorphicComponentWithRef<'div', SpinnerProps>

Spinner.displayName = 'Spinner'

'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { RadioSize } from './Radio.props'
import { radioVariants } from './Radio.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type RadioProps<T extends React.ElementType = 'input'> = PolymorphicProps<
  T,
  {
    size?: RadioSize
    className?: string
    name?: string
    value?: string
    checked?: boolean
    onChange?: (event: React.ChangeEvent<HTMLInputElement>) => void
  }
>

export const Radio = React.forwardRef(
  <T extends React.ElementType = 'input'>(
    { as, size = 'md', className, ...props }: RadioProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'input') as React.ElementType

    return (
      <Component
        type="radio"
        ref={ref}
        className={cn(radioVariants({ size }), className)}
        {...props}
      />
    )
  }
) as PolymorphicComponentWithRef<'input', RadioProps>

Radio.displayName = 'Radio'

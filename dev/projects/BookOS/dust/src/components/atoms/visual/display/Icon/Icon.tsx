'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { IconSize, IconTone } from './Icon.props'
import { iconVariants } from './Icon.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type IconProps<T extends React.ElementType = 'svg'> = PolymorphicProps<
  T,
  {
    size?: IconSize
    tone?: IconTone
    className?: string
  }
>

export const Icon = React.forwardRef(
  <T extends React.ElementType = 'svg'>(
    { as, size = 'md', tone = 'default', className, children, ...props }: IconProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'svg') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(iconVariants({ size, tone }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'svg', IconProps>

Icon.displayName = 'Icon'

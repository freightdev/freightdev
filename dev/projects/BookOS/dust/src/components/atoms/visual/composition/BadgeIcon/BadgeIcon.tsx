'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  BadgeIconBorder,
  BadgeIconPosition,
  BadgeIconSize,
  BadgeIconTone,
} from './BadgeIcon.props'
import { badgeIconVariants } from './BadgeIcon.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type BadgeIconProps<T extends React.ElementType = 'span'> = PolymorphicProps<
  T,
  {
    tone?: BadgeIconTone
    size?: BadgeIconSize
    position?: BadgeIconPosition
    border?: BadgeIconBorder
    className?: string
  }
>

export const BadgeIcon = React.forwardRef(
  <T extends React.ElementType = 'span'>(
    {
      as,
      tone = 'default',
      size = 'sm',
      position = 'topRight',
      border = 'light',
      className,
      ...props
    }: BadgeIconProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'span') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(
          badgeIconVariants({ tone, size, position, border }),
          className
        )}
        {...props}
      />
    )
  }
) as PolymorphicComponentWithRef<'span', BadgeIconProps>

BadgeIcon.displayName = 'BadgeIcon'

'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type { AvatarShape, AvatarSize } from './Avatar.props'
import { avatarVariants } from './Avatar.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type AvatarProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    size?: AvatarSize
    shape?: AvatarShape
    className?: string
  }
>

export const Avatar = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    {
      as,
      size = 'md',
      shape = 'circle',
      className,
      children,
      ...props
    }: AvatarProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(avatarVariants({ size, shape }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'div', AvatarProps>

Avatar.displayName = 'Avatar'

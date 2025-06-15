'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import NextLink from 'next/link'
import * as React from 'react'
import type { LinkSize, LinkVariant } from './Link.props'
import { linkVariants } from './Link.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type LinkProps<T extends React.ElementType = 'a'> = PolymorphicProps<
  T,
  {
    variant?: LinkVariant
    size?: LinkSize
    className?: string
    href?: string
  }
>

export const Link = React.forwardRef(
  <T extends React.ElementType = 'a'>(
    {
      as,
      href,
      className,
      variant = 'default',
      size = 'md',
      children,
      ...props
    }: LinkProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || NextLink) as React.ElementType

    return (
      <Component
        ref={ref}
        {...(href ? { href } : {})}
        className={cn(linkVariants({ variant, size }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'a', LinkProps>

Link.displayName = 'Link'

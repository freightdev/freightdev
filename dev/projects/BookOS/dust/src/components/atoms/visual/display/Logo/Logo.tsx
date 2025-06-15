'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  LogoAlign,
  LogoGap,
  LogoSize,
  LogoStyle,
} from './Logo.props'
import { logoVariants } from './Logo.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type LogoProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    size?: LogoSize
    style?: LogoStyle
    align?: LogoAlign
    gap?: LogoGap
    className?: string
  }
>

export const Logo = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    {
      as,
      size = 'md',
      style = 'text',
      align = 'left',
      gap = 'md',
      className,
      children,
      ...props
    }: LogoProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(logoVariants({ size, style, align, gap }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'div', LogoProps>

Logo.displayName = 'Logo'

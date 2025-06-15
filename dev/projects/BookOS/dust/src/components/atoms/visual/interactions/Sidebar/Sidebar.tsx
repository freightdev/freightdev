'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  SidebarBorder,
  SidebarPosition,
  SidebarRounded,
  SidebarShadow,
  SidebarSize,
  SidebarTone,
} from './Sidebar.props'
import { sidebarVariants } from './Sidebar.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type SidebarProps<T extends React.ElementType = 'aside'> = PolymorphicProps<
  T,
  {
    position?: SidebarPosition
    tone?: SidebarTone
    size?: SidebarSize
    border?: SidebarBorder
    shadow?: SidebarShadow
    rounded?: SidebarRounded
    className?: string
  }
>

export const Sidebar = React.forwardRef(
  <T extends React.ElementType = 'aside'>(
    {
      as,
      position = 'left',
      tone = 'default',
      size = 'md',
      border = 'right',
      shadow = 'md',
      rounded = 'none',
      className,
      children,
      ...props
    }: SidebarProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'aside') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(
          sidebarVariants({ position, tone, size, border, shadow, rounded }),
          className
        )}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'aside', SidebarProps>

Sidebar.displayName = 'Sidebar'

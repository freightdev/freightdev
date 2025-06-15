'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  MenuOrientation,
  MenuSize,
  MenuTone,
} from './Menu.props'
import { menuVariants } from './Menu.variants'

export type MenuProps<T extends React.ElementType = 'menu'> = {
  orientation?: MenuOrientation
  size?: MenuSize
  tone?: MenuTone
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function MenuInner(props: MenuProps, ref: React.Ref<any>) {
  const {
    orientation = 'vertical',
    size = 'md',
    tone = 'default',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'menu') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(menuVariants({ orientation, size, tone }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const MenuBase = React.forwardRef(MenuInner)
MenuBase.displayName = 'Menu'

export function Menu<T extends React.ElementType = 'menu'>(
  props: MenuProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <MenuBase {...props} />
}

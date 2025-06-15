'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { navVariants } from './Nav.variants'
import type {
  NavPosition,
  NavPadding,
  NavBg,
  NavBorder,
} from './Nav.props'

export type NavProps<T extends React.ElementType = 'nav'> = {
  position?: NavPosition
  padding?: NavPadding
  bg?: NavBg
  border?: NavBorder
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

// 1. Internal forwardRef-safe function
function NavInner(props: NavProps, ref: React.Ref<any>) {
  const {
    position = 'sticky',
    padding = 'md',
    bg = 'white',
    border = 'bottom',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'nav') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(navVariants({ position, padding, bg, border }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

// 2. ForwardRef base
const NavBase = React.forwardRef(NavInner)
NavBase.displayName = 'Nav'

// 3. Generic wrapper
export function Nav<T extends React.ElementType = 'nav'>(
  props: NavProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error TS doesn't like forwardRef + generics
  return <NavBase {...props} />
}

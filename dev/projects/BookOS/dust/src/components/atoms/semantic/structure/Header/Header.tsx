'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { headerVariants } from './Header.variants'
import type {
  HeaderPadding,
  HeaderShadow,
  HeaderBorder,
  HeaderBg,
} from './Header.props'

export type HeaderProps<T extends React.ElementType = 'header'> = {
  padding?: HeaderPadding
  shadow?: HeaderShadow
  border?: HeaderBorder
  bg?: HeaderBg
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function HeaderInner(props: HeaderProps, ref: React.Ref<any>) {
  const {
    padding = 'md',
    shadow = 'none',
    border = 'bottom',
    bg = 'white',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'header') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(headerVariants({ padding, shadow, border, bg }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const HeaderBase = React.forwardRef(HeaderInner)
HeaderBase.displayName = 'Header'

export function Header<T extends React.ElementType = 'header'>(
  props: HeaderProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <HeaderBase {...props} />
}

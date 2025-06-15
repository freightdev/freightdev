'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { footerVariants } from './Footer.variants'
import type {
  FooterPadding,
  FooterBorder,
  FooterBg,
} from './Footer.props'

export type FooterProps<T extends React.ElementType = 'footer'> = {
  padding?: FooterPadding
  border?: FooterBorder
  bg?: FooterBg
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

// 1. Inner base (non-generic)
function FooterInner(props: FooterProps, ref: React.Ref<any>) {
  const {
    padding = 'md',
    border = 'top',
    bg = 'muted',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'footer') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(footerVariants({ padding, border, bg }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

// 2. Forwarded wrapper
const FooterBase = React.forwardRef(FooterInner)
FooterBase.displayName = 'Footer'

// 3. Generic wrapper with TS bypass
export function Footer<T extends React.ElementType = 'footer'>(
  props: FooterProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error TS doesn't like forwardRef+generics
  return <FooterBase {...props} />
}

'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { mainVariants } from './Main.variants'
import type { MainPadding, MainBg } from './Main.props'

export type MainProps<T extends React.ElementType = 'main'> = {
  padding?: MainPadding
  bg?: MainBg
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

// 1. Non-generic for forwardRef
function MainInner(props: MainProps, ref: React.Ref<any>) {
  const {
    padding = 'md',
    bg = 'none',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'main') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(mainVariants({ padding, bg }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

// 2. Ref passthrough base
const MainBase = React.forwardRef(MainInner)
MainBase.displayName = 'Main'

// 3. Generic wrapper for polymorphic use
export function Main<T extends React.ElementType = 'main'>(
  props: MainProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error generic with forwardRef
  return <MainBase {...props} />
}

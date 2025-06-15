'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { shellVariants } from './Shell.variants'
import type {
  ShellMaxWidth,
  ShellPadding,
  ShellCenter,
} from './Shell.props'

export type ShellProps<T extends React.ElementType = 'div'> = {
  maxWidth?: ShellMaxWidth
  padding?: ShellPadding
  center?: ShellCenter
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function ShellInner(props: ShellProps, ref: React.Ref<any>) {
  const {
    maxWidth = 'xl',
    padding = 'md',
    center = true,
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'div') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(shellVariants({ maxWidth, padding, center }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const ShellBase = React.forwardRef(ShellInner)
ShellBase.displayName = 'Shell'

export function Shell<T extends React.ElementType = 'div'>(
  props: ShellProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic TS issue
  return <ShellBase {...props} />
}

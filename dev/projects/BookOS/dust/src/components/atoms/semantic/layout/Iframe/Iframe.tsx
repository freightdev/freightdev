'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  IframeBorder,
  IframeRadius,
  IframeShadow,
  IframeSize,
} from './Iframe.props'
import { iframeVariants } from './Iframe.variants'

export type IframeProps<T extends React.ElementType = 'iframe'> = {
  size?: IframeSize
  border?: IframeBorder
  radius?: IframeRadius
  shadow?: IframeShadow
  as?: T
  className?: string
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function IframeInner(props: IframeProps, ref: React.Ref<any>) {
  const {
    size = 'md',
    border = 'none',
    radius = 'none',
    shadow = 'none',
    as,
    className,
    ...rest
  } = props

  const Component = (as || 'iframe') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(iframeVariants({ size, border, radius, shadow }), className)}
      {...rest}
    />
  )
}

const IframeBase = React.forwardRef(IframeInner)
IframeBase.displayName = 'Iframe'

export function Iframe<T extends React.ElementType = 'iframe'>(
  props: IframeProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <IframeBase {...props} />
}

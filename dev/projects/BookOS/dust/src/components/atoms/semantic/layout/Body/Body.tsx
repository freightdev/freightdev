'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  BodyBg,
  BodyFont,
  BodySpacing,
} from './Body.props'
import { bodyVariants } from './Body.variants'

export type BodyProps<T extends React.ElementType = 'body'> = {
  bg?: BodyBg
  font?: BodyFont
  spacing?: BodySpacing
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function BodyInner(props: BodyProps, ref: React.Ref<any>) {
  const {
    bg = 'white',
    font = 'sans',
    spacing = 'normal',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'body') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(bodyVariants({ bg, font, spacing }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const BodyBase = React.forwardRef(BodyInner)
BodyBase.displayName = 'Body'

export function Body<T extends React.ElementType = 'body'>(
  props: BodyProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <BodyBase {...props} />
}

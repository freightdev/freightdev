'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  FigcaptionAlign,
  FigcaptionSize,
  FigcaptionTone,
} from './Figcaption.props'
import { figcaptionVariants } from './Figcaption.variants'

export type FigcaptionProps<T extends React.ElementType = 'figcaption'> = {
  tone?: FigcaptionTone
  align?: FigcaptionAlign
  size?: FigcaptionSize
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function FigcaptionInner(props: FigcaptionProps, ref: React.Ref<any>) {
  const {
    tone = 'muted',
    align = 'center',
    size = 'sm',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'figcaption') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(figcaptionVariants({ tone, align, size }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const FigcaptionBase = React.forwardRef(FigcaptionInner)
FigcaptionBase.displayName = 'Figcaption'

export function Figcaption<T extends React.ElementType = 'figcaption'>(
  props: FigcaptionProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <FigcaptionBase {...props} />
}

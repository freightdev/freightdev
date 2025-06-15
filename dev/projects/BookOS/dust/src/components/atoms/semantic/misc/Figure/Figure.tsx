'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  FigureAlign,
  FigurePadding,
} from './Figure.props'
import { figureVariants } from './Figure.variants'

export type FigureProps<T extends React.ElementType = 'figure'> = {
  align?: FigureAlign
  padding?: FigurePadding
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function FigureInner(props: FigureProps, ref: React.Ref<any>) {
  const {
    align = 'center',
    padding = 'md',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'figure') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(figureVariants({ align, padding }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const FigureBase = React.forwardRef(FigureInner)
FigureBase.displayName = 'Figure'

export function Figure<T extends React.ElementType = 'figure'>(
  props: FigureProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <FigureBase {...props} />
}

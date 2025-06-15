'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  CanvasBg,
  CanvasBorder,
  CanvasSize,
} from './Canvas.props'
import { canvasVariants } from './Canvas.variants'

export type CanvasProps<T extends React.ElementType = 'canvas'> = {
  size?: CanvasSize
  bg?: CanvasBg
  border?: CanvasBorder
  as?: T
  className?: string
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function CanvasInner(props: CanvasProps, ref: React.Ref<any>) {
  const {
    size = 'md',
    bg = 'none',
    border = 'none',
    as,
    className,
    ...rest
  } = props

  const Component = (as || 'canvas') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(canvasVariants({ size, bg, border }), className)}
      {...rest}
    />
  )
}

const CanvasBase = React.forwardRef(CanvasInner)
CanvasBase.displayName = 'Canvas'

export function Canvas<T extends React.ElementType = 'canvas'>(
  props: CanvasProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <CanvasBase {...props} />
}

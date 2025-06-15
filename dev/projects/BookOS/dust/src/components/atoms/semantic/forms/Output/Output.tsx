'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  OutputBorder,
  OutputSize,
  OutputTone,
} from './Output.props'
import { outputVariants } from './Output.variants'

export type OutputProps<T extends React.ElementType = 'output'> = {
  tone?: OutputTone
  size?: OutputSize
  border?: OutputBorder
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function OutputInner(props: OutputProps, ref: React.Ref<any>) {
  const {
    tone = 'default',
    size = 'md',
    border = 'none',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'output') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(outputVariants({ tone, size, border }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const OutputBase = React.forwardRef(OutputInner)
OutputBase.displayName = 'Output'

export function Output<T extends React.ElementType = 'output'>(
  props: OutputProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <OutputBase {...props} />
}

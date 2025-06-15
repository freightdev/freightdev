'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  DatalistSize,
  DatalistTone,
} from './Datalist.props'
import { datalistVariants } from './Datalist.variants'

export type DatalistProps<T extends React.ElementType = 'datalist'> = {
  size?: DatalistSize
  tone?: DatalistTone
  as?: T
  className?: string
  children?: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function DatalistInner(props: DatalistProps, ref: React.Ref<any>) {
  const {
    size = 'md',
    tone = 'default',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'datalist') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(datalistVariants({ size, tone }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const DatalistBase = React.forwardRef(DatalistInner)
DatalistBase.displayName = 'Datalist'

export function Datalist<T extends React.ElementType = 'datalist'>(
  props: DatalistProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <DatalistBase {...props} />
}

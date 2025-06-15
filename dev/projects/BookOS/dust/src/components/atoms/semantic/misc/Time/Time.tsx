'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  TimeSize,
  TimeTone,
  TimeWeight,
} from './Time.props'
import { timeVariants } from './Time.variants'

export type TimeProps<T extends React.ElementType = 'time'> = {
  tone?: TimeTone
  size?: TimeSize
  weight?: TimeWeight
  as?: T
  className?: string
  dateTime?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function TimeInner(props: TimeProps, ref: React.Ref<any>) {
  const {
    tone = 'muted',
    size = 'sm',
    weight = 'normal',
    as,
    className,
    dateTime,
    children,
    ...rest
  } = props

  const Component = (as || 'time') as React.ElementType

  return (
    <Component
      ref={ref}
      dateTime={dateTime}
      className={cn(timeVariants({ tone, size, weight }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const TimeBase = React.forwardRef(TimeInner)
TimeBase.displayName = 'Time'

export function Time<T extends React.ElementType = 'time'>(
  props: TimeProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <TimeBase {...props} />
}

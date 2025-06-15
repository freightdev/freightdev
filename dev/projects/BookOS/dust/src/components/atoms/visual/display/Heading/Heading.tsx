'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { headingVariants } from './Heading.variants'
import type {
  HeadingLevel,
  HeadingTone,
  HeadingSpacing,
} from './Heading.props'

export type HeadingProps<T extends React.ElementType = 'h2'> = {
  level?: HeadingLevel
  tone?: HeadingTone
  spacing?: HeadingSpacing
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

// 1. Inner non-generic for forwardRef
function HeadingInner(
  props: HeadingProps,
  ref: React.Ref<any>
) {
  const {
    level = 'h2',
    tone = 'default',
    spacing = 'md',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || level) as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(headingVariants({ level, tone, spacing }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

// 2. Standard forwardRef binding
const HeadingBase = React.forwardRef(HeadingInner)
HeadingBase.displayName = 'Heading'

// 3. Generic outer wrapper for polymorphism
export function Heading<T extends React.ElementType = 'h2'>(
  props: HeadingProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error — ForwardRef + generics limitation
  return <HeadingBase {...props} />
}

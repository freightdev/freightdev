'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { sectionVariants } from './Section.variants'
import type {
  SectionSpacing,
  SectionDivider,
  SectionBg,
} from './Section.props'

export type SectionProps<T extends React.ElementType = 'section'> = {
  spacing?: SectionSpacing
  divider?: SectionDivider
  bg?: SectionBg
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

// 1. Non-generic forwardRef-safe
function SectionInner(props: SectionProps, ref: React.Ref<any>) {
  const {
    spacing = 'md',
    divider = 'none',
    bg = 'none',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'section') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(sectionVariants({ spacing, divider, bg }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

// 2. Ref-safe base
const SectionBase = React.forwardRef(SectionInner)
SectionBase.displayName = 'Section'

// 3. Generic wrapper
export function Section<T extends React.ElementType = 'section'>(
  props: SectionProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error generic+ref TS bug
  return <SectionBase {...props} />
}

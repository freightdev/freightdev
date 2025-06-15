'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { asideVariants } from './Aside.variants'
import type {
  AsideWidth,
  AsidePosition,
  AsidePadding,
  AsideBg,
} from './Aside.props'

export type AsideProps<T extends React.ElementType = 'aside'> = {
  width?: AsideWidth
  position?: AsidePosition
  padding?: AsidePadding
  bg?: AsideBg
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function AsideInner(props: AsideProps, ref: React.Ref<any>) {
  const {
    width = 'md',
    position = 'static',
    padding = 'md',
    bg = 'none',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'aside') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(asideVariants({ width, position, padding, bg }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const AsideBase = React.forwardRef(AsideInner)
AsideBase.displayName = 'Aside'

export function Aside<T extends React.ElementType = 'aside'>(
  props: AsideProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error TS hates generics + forwardRef
  return <AsideBase {...props} />
}

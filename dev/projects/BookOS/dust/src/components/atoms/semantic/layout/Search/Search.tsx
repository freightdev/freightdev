'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  SearchRadius,
  SearchSize,
  SearchVariant,
} from './Search.props'
import { searchVariants } from './Search.variants'

export type SearchProps<T extends React.ElementType = 'input'> = {
  size?: SearchSize
  radius?: SearchRadius
  variant?: SearchVariant
  as?: T
  className?: string
  placeholder?: string
} & Omit<React.ComponentPropsWithoutRef<T>, 'as' | 'type'>

function SearchInner(props: SearchProps, ref: React.Ref<any>) {
  const {
    size = 'md',
    radius = 'md',
    variant = 'default',
    as,
    className,
    placeholder = 'Search...',
    ...rest
  } = props

  const Component = (as || 'input') as React.ElementType

  return (
    <Component
      ref={ref}
      type="search"
      placeholder={placeholder}
      className={cn(searchVariants({ size, radius, variant }), className)}
      {...rest}
    />
  )
}

const SearchBase = React.forwardRef(SearchInner)
SearchBase.displayName = 'Search'

export function Search<T extends React.ElementType = 'input'>(
  props: SearchProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <SearchBase {...props} />
}

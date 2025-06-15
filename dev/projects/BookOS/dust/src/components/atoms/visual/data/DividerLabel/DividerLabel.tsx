'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  DividerLabelAlign,
  DividerLabelLineStyle,
  DividerLabelSize,
  DividerLabelTone,
} from './DividerLabel.props'
import { dividerLabelVariants } from './DividerLabel.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type DividerLabelProps<T extends React.ElementType = 'div'> = PolymorphicProps<
  T,
  {
    align?: DividerLabelAlign
    tone?: DividerLabelTone
    size?: DividerLabelSize
    lineStyle?: DividerLabelLineStyle
    className?: string
  }
>

export const DividerLabel = React.forwardRef(
  <T extends React.ElementType = 'div'>(
    {
      as,
      align = 'center',
      tone = 'default',
      size = 'sm',
      lineStyle = 'solid',
      className,
      children,
      ...props
    }: DividerLabelProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'div') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(dividerLabelVariants({ align, tone, size, lineStyle }), className)}
        {...props}
      >
        <div className="flex-1 border-t" />
        <span className="shrink-0 px-2">{children}</span>
        <div className="flex-1 border-t" />
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'div', DividerLabelProps>

DividerLabel.displayName = 'DividerLabel'

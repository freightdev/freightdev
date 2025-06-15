'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  TextLeadAlign,
  TextLeadSize,
  TextLeadTone,
  TextLeadWeight,
} from './TextLead.props'
import { textLeadVariants } from './TextLead.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type TextLeadProps<T extends React.ElementType = 'p'> = PolymorphicProps<
  T,
  {
    size?: TextLeadSize
    tone?: TextLeadTone
    weight?: TextLeadWeight
    align?: TextLeadAlign
    className?: string
  }
>

export const TextLead = React.forwardRef(
  <T extends React.ElementType = 'p'>(
    {
      as,
      size = 'md',
      tone = 'default',
      weight = 'normal',
      align = 'left',
      className,
      children,
      ...props
    }: TextLeadProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'p') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(textLeadVariants({ size, tone, weight, align }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'p', TextLeadProps>

TextLead.displayName = 'TextLead'

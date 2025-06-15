'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  TabAlign,
  TabDisabled,
  TabRounded,
  TabSize,
  TabTone,
} from './Tab.props'
import { tabVariants } from './Tab.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type TabProps<T extends React.ElementType = 'button'> = PolymorphicProps<
  T,
  {
    tone?: TabTone
    size?: TabSize
    align?: TabAlign
    rounded?: TabRounded
    disabled?: TabDisabled
    className?: string
  }
>

export const Tab = React.forwardRef(
  <T extends React.ElementType = 'button'>(
    {
      as,
      tone = 'default',
      size = 'md',
      align = 'center',
      rounded = 'none',
      disabled = false,
      className,
      children,
      ...props
    }: TabProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'button') as React.ElementType

    return (
      <Component
        ref={ref}
        aria-disabled={disabled === true}
        className={cn(tabVariants({ tone, size, align, rounded, disabled }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'button', TabProps>

Tab.displayName = 'Tab'

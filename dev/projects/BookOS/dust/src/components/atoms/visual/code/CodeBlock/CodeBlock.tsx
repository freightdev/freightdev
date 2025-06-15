'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  CodeBlockRounded,
  CodeBlockSize,
  CodeBlockTone
} from './CodeBlock.props'
import { codeBlockVariants } from './CodeBlock.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type CodeBlockProps<T extends React.ElementType = 'pre'> = PolymorphicProps<
  T,
  {
    tone?: CodeBlockTone
    size?: CodeBlockSize
    rounded?: CodeBlockRounded
    className?: string
  }
>

export const CodeBlock = React.forwardRef(
  <T extends React.ElementType = 'pre'>(
    {
      as,
      tone = 'default',
      size = 'sm',
      rounded = 'md',
      className,
      children,
      ...props
    }: CodeBlockProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'pre') as React.ElementType

    return (
      <Component
        ref={ref}
        className={cn(codeBlockVariants({ tone, size, rounded }), className)}
        {...props}
      >
        {children}
      </Component>
    )
  }
) as PolymorphicComponentWithRef<'pre', CodeBlockProps>

CodeBlock.displayName = 'CodeBlock'

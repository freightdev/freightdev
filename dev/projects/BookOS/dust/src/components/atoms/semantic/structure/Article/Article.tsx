'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { articleVariants } from './Article.variants'
import type {
  ArticleSpacing,
  ArticleWidth,
  ArticleAlign,
} from './Article.props'

export type ArticleProps<T extends React.ElementType = 'article'> = {
  spacing?: ArticleSpacing
  width?: ArticleWidth
  align?: ArticleAlign
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function ArticleInner(props: ArticleProps, ref: React.Ref<any>) {
  const {
    spacing = 'md',
    width = 'narrow',
    align = 'center',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'article') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(articleVariants({ spacing, width, align }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const ArticleBase = React.forwardRef(ArticleInner)
ArticleBase.displayName = 'Article'

export function Article<T extends React.ElementType = 'article'>(
  props: ArticleProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error — forwardRef + generic
  return <ArticleBase {...props} />
}

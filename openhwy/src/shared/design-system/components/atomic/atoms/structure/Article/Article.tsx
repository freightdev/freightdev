'use client'

import * as React from 'react'

export interface ArticleProps extends React.HTMLAttributes<HTMLElement> {}

export const Article = React.forwardRef<HTMLElement, ArticleProps>(
  ({ children, ...props }, ref) => {
    return (
      <article ref={ref} {...props}>
        {children}
      </article>
    )
  }
)

Article.displayName = 'Article'

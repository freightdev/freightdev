'use client'

import * as React from 'react'

export interface CodeBlockProps extends React.HTMLAttributes<HTMLPreElement> {}

export const CodeBlock = React.forwardRef<HTMLPreElement, CodeBlockProps>(
  ({ children, ...props }, ref) => {
    return (
      <pre ref={ref} {...props}>
        <code>{children}</code>
      </pre>
    )
  }
)

CodeBlock.displayName = 'CodeBlock'

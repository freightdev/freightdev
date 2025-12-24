'use client'

import * as React from 'react'

export interface ScriptProps extends React.ScriptHTMLAttributes<HTMLScriptElement> {}

export const Script = React.forwardRef<HTMLScriptElement, ScriptProps>(
  ({ ...props }, ref) => {
    return (
      <script
        ref={ref}
        {...props}
      />
    )
  }
)

Script.displayName = 'Script'

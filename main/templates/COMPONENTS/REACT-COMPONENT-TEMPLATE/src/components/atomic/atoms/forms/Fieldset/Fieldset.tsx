'use client'

import * as React from 'react'

export interface FieldsetProps extends React.HTMLAttributes<HTMLFieldSetElement> {}

export const Fieldset = React.forwardRef<HTMLFieldSetElement, FieldsetProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <fieldset
        ref={ref}
        className={className}
        {...props}
      >
        {children}
      </fieldset>
    )
  }
)

Fieldset.displayName = 'Fieldset'

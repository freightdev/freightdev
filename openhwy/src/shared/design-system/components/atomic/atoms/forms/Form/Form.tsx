'use client'

import * as React from 'react'

export interface FormProps extends React.FormHTMLAttributes<HTMLFormElement> {}

export const Form = React.forwardRef<HTMLFormElement, FormProps>(
  ({ children, className, ...props }, ref) => {
    return (
      <form
        ref={ref}
        className={className}
        {...props}
      >
        {children}
      </form>
    )
  }
)

Form.displayName = 'Form'

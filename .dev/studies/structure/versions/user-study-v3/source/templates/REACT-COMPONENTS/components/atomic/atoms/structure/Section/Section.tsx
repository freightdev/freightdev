'use client'

import * as React from 'react'

export interface SectionProps extends React.HTMLAttributes<HTMLElement> {}

export const Section = React.forwardRef<HTMLElement, SectionProps>(
  ({ children, ...props }, ref) => {
    return (
      <section ref={ref} {...props}>
        {children}
      </section>
    )
  }
)

Section.displayName = 'Section'

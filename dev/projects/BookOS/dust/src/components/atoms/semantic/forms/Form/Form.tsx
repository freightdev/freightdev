'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { formVariants } from './Form.variants'
import type {
  FormPadding,
  FormSpacing,
  FormBg,
} from './Form.props'

export type FormProps<T extends React.ElementType = 'form'> = {
  padding?: FormPadding
  spacing?: FormSpacing
  bg?: FormBg
  as?: T
  className?: string
  children: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function FormInner(props: FormProps, ref: React.Ref<any>) {
  const {
    padding = 'md',
    spacing = 'md',
    bg = 'none',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'form') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(formVariants({ padding, spacing, bg }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const FormBase = React.forwardRef(FormInner)
FormBase.displayName = 'Form'

export function Form<T extends React.ElementType = 'form'>(
  props: FormProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <FormBase {...props} />
}

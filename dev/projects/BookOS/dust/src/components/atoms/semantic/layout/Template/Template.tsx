'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  TemplateBg,
  TemplateGap,
  TemplatePadding,
} from './Template.props'
import { templateVariants } from './Template.variants'

export type TemplateProps<T extends React.ElementType = 'template'> = {
  padding?: TemplatePadding
  bg?: TemplateBg
  gap?: TemplateGap
  as?: T
  className?: string
  children?: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function TemplateInner(props: TemplateProps, ref: React.Ref<any>) {
  const {
    padding = 'md',
    bg = 'none',
    gap = 'none',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'template') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(templateVariants({ padding, bg, gap }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const TemplateBase = React.forwardRef(TemplateInner)
TemplateBase.displayName = 'Template'

export function Template<T extends React.ElementType = 'template'>(
  props: TemplateProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <TemplateBase {...props} />
}

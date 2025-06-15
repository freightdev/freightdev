'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  ScriptAsync,
  ScriptType,
} from './Script.props'
import { scriptVariants } from './Script.variants'

export type ScriptProps<T extends React.ElementType = 'script'> = {
  type?: ScriptType
  async?: ScriptAsync
  src?: string
  as?: T
  className?: string
  children?: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function ScriptInner(props: ScriptProps, ref: React.Ref<any>) {
  const {
    type = 'text/javascript',
    async = false,
    src,
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'script') as React.ElementType

  return (
    <Component
      ref={ref}
      type={type}
      async={async}
      src={src}
      className={cn(scriptVariants(), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const ScriptBase = React.forwardRef(ScriptInner)
ScriptBase.displayName = 'Script'

export function Script<T extends React.ElementType = 'script'>(
  props: ScriptProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <ScriptBase {...props} />
}

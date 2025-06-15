'use client'

import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  AudioBorder,
  AudioRadius,
  AudioShadow
} from './Audio.props'
import { audioVariants } from './Audio.variants'

export type AudioProps<T extends React.ElementType = 'audio'> = {
  radius?: AudioRadius
  shadow?: AudioShadow
  border?: AudioBorder
  as?: T
  className?: string
  children?: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function AudioInner(props: AudioProps, ref: React.Ref<any>) {
  const {
    radius = 'none',
    shadow = 'none',
    border = 'none',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'audio') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(audioVariants({ radius, shadow, border }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const AudioBase = React.forwardRef(AudioInner)
AudioBase.displayName = 'Audio'

export function Audio<T extends React.ElementType = 'audio'>(
  props: AudioProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <AudioBase {...props} />
}

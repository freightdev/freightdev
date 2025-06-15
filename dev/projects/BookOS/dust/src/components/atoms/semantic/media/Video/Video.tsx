'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { videoVariants } from './Video.variants'
import type {
  VideoRadius,
  VideoShadow,
  VideoBorder,
  VideoControls,
} from './Video.props'

export type VideoProps<T extends React.ElementType = 'video'> = {
  radius?: VideoRadius
  shadow?: VideoShadow
  border?: VideoBorder
  controlsVariant?: VideoControls
  as?: T
  className?: string
  children?: React.ReactNode
} & Omit<React.ComponentPropsWithoutRef<T>, 'as'>

function VideoInner(props: VideoProps, ref: React.Ref<any>) {
  const {
    radius = 'none',
    shadow = 'none',
    border = 'none',
    controlsVariant = 'default',
    as,
    className,
    children,
    ...rest
  } = props

  const Component = (as || 'video') as React.ElementType

  return (
    <Component
      ref={ref}
      className={cn(videoVariants({ radius, shadow, border, controlsVariant }), className)}
      {...rest}
    >
      {children}
    </Component>
  )
}

const VideoBase = React.forwardRef(VideoInner)
VideoBase.displayName = 'Video'

export function Video<T extends React.ElementType = 'video'>(
  props: VideoProps<T> & { ref?: React.Ref<any> }
) {
  // @ts-expect-error forwardRef + generic
  return <VideoBase {...props} />
}

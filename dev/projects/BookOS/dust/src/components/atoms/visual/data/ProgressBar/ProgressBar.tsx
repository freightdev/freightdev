'use client'

import * as React from 'react'
import { cn } from '@ui/utils'
import { progressBarVariants } from './ProgressBar.variants'
import type {
  ProgressBarSize,
  ProgressBarTone,
  ProgressBarRounded,
} from './ProgressBar.props'

export type ProgressBarProps = {
  value: number // 0-100
  size?: ProgressBarSize
  tone?: ProgressBarTone
  rounded?: ProgressBarRounded
  className?: string
} & React.ComponentPropsWithoutRef<'div'>

export const ProgressBar = React.forwardRef<HTMLDivElement, ProgressBarProps>(
  (
    {
      value,
      size = 'md',
      tone = 'default',
      rounded = 'md',
      className,
      ...props
    },
    ref
  ) => {
    const clampedValue = Math.min(Math.max(value, 0), 100)

    return (
      <div
        ref={ref}
        role="progressbar"
        aria-valuenow={clampedValue}
        aria-valuemin={0}
        aria-valuemax={100}
        className={cn(progressBarVariants({ size, tone, rounded }), className)}
        {...props}
      >
        <div
          className="h-full bg-current transition-all duration-300"
          style={{ width: `${clampedValue}%` }}
        />
      </div>
    )
  }
)

ProgressBar.displayName = 'ProgressBar'

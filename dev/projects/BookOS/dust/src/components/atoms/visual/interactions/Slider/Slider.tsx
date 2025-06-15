'use client'

import type { PolymorphicComponentWithRef } from '@ui/types/polymorphic'
import { cn } from '@ui/utils'
import * as React from 'react'
import type {
  SliderRounded,
  SliderSize,
  SliderTone,
  SliderTrackHeight,
} from './Slider.props'
import { sliderVariants } from './Slider.variants'

type AsProp<T extends React.ElementType> = {
  as?: T
}

type PolymorphicProps<
  T extends React.ElementType,
  Props = {}
> = React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>

export type SliderProps<T extends React.ElementType = 'input'> = PolymorphicProps<
  T,
  {
    tone?: SliderTone
    size?: SliderSize
    rounded?: SliderRounded
    trackHeight?: SliderTrackHeight
    className?: string
    value?: number
    min?: number
    max?: number
    step?: number
    onChange?: React.ChangeEventHandler<HTMLInputElement>
  }
>

export const Slider = React.forwardRef(
  <T extends React.ElementType = 'input'>(
    {
      as,
      tone = 'default',
      size = 'md',
      rounded = 'full',
      trackHeight = 'medium',
      className,
      value,
      min = 0,
      max = 100,
      step = 1,
      onChange,
      ...props
    }: SliderProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = (as || 'input') as React.ElementType

    return (
      <Component
        ref={ref}
        type="range"
        value={value}
        min={min}
        max={max}
        step={step}
        onChange={onChange}
        className={cn(sliderVariants({ tone, size, rounded, trackHeight }), className)}
        {...props}
      />
    )
  }
) as PolymorphicComponentWithRef<'input', SliderProps>

Slider.displayName = 'Slider'

import { cva, type VariantProps } from 'class-variance-authority'

export const sliderVariants = cva('appearance-none w-full cursor-pointer', {
  variants: {
    tone: {
      default: 'accent-muted',
      primary: 'accent-primary',
      success: 'accent-green-500',
      danger: 'accent-red-500',
    },
    size: {
      sm: 'h-1',
      md: 'h-1.5',
      lg: 'h-2',
    },
    rounded: {
      none: '',
      full: 'rounded-full',
    },
    trackHeight: {
      thin: 'h-1',
      medium: 'h-2',
      thick: 'h-3',
    },
  },
  defaultVariants: {
    tone: 'default',
    size: 'md',
    rounded: 'full',
    trackHeight: 'medium',
  },
})

export type SliderVariants = VariantProps<typeof sliderVariants>

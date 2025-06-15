import { cva, type VariantProps } from 'class-variance-authority'

export const videoVariants = cva('', {
  variants: {
    radius: {
      none: '',
      sm: 'rounded-sm',
      md: 'rounded-md',
      lg: 'rounded-lg',
      full: 'rounded-full',
    },
    shadow: {
      none: '',
      sm: 'shadow-sm',
      md: 'shadow-md',
      lg: 'shadow-lg',
    },
    border: {
      none: '',
      default: 'border',
      muted: 'border border-muted',
    },
    controlsVariant: {
      default: '',
      chrome: 'bg-black bg-opacity-70',
    },
  },
  defaultVariants: {
    radius: 'none',
    shadow: 'none',
    border: 'none',
    controlsVariant: 'default',
  },
})

export type VideoVariants = VariantProps<typeof videoVariants>

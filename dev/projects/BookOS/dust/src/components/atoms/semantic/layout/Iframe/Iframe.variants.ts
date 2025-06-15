import { cva, type VariantProps } from 'class-variance-authority'

export const iframeVariants = cva('', {
  variants: {
    size: {
      sm: 'w-64 h-36',
      md: 'w-96 h-56',
      lg: 'w-full h-96',
      full: 'w-full h-full',
    },
    border: {
      none: '',
      default: 'border',
      muted: 'border border-muted',
    },
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
  },
  defaultVariants: {
    size: 'md',
    border: 'none',
    radius: 'none',
    shadow: 'none',
  },
})

export type IframeVariants = VariantProps<typeof iframeVariants>

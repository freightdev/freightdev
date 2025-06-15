import { cva, type VariantProps } from 'class-variance-authority'

export const audioVariants = cva('', {
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
  },
  defaultVariants: {
    radius: 'none',
    shadow: 'none',
    border: 'none',
  },
})

export type AudioVariants = VariantProps<typeof audioVariants>

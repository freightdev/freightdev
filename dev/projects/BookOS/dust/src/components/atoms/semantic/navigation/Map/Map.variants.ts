import { cva, type VariantProps } from 'class-variance-authority'

export const mapVariants = cva('', {
  variants: {
    size: {
      sm: 'w-48 h-48',
      md: 'w-64 h-64',
      lg: 'w-96 h-96',
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
  },
  defaultVariants: {
    size: 'md',
    border: 'none',
    radius: 'none',
  },
})

export type MapVariants = VariantProps<typeof mapVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const imgVariants = cva('', {
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
    fit: {
      cover: 'object-cover',
      contain: 'object-contain',
      fill: 'object-fill',
      none: 'object-none',
    },
  },
  defaultVariants: {
    radius: 'none',
    shadow: 'none',
    border: 'none',
    fit: 'cover',
  },
})

export type ImgVariants = VariantProps<typeof imgVariants>

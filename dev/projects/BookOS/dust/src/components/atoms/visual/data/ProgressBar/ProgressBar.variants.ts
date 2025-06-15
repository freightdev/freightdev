import { cva, type VariantProps } from 'class-variance-authority'

export const progressBarVariants = cva('relative w-full overflow-hidden rounded', {
  variants: {
    size: {
      sm: 'h-1.5',
      md: 'h-2',
      lg: 'h-3',
    },
    tone: {
      default: 'bg-muted',
      primary: 'bg-primary/20',
      destructive: 'bg-red-200',
    },
    rounded: {
      none: '',
      sm: 'rounded-sm',
      md: 'rounded-md',
      lg: 'rounded-full',
    },
  },
  defaultVariants: {
    size: 'md',
    tone: 'default',
    rounded: 'md',
  },
})

export type ProgressBarVariants = VariantProps<typeof progressBarVariants>

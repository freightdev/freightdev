import { cva, type VariantProps } from 'class-variance-authority'

export const spinnerVariants = cva(
  'animate-spin rounded-full border-2 border-t-transparent',
  {
    variants: {
      size: {
        xs: 'h-3 w-3',
        sm: 'h-4 w-4',
        md: 'h-5 w-5',
        lg: 'h-6 w-6',
        xl: 'h-8 w-8',
      },
      tone: {
        default: 'border-muted',
        primary: 'border-primary',
        destructive: 'border-red-600',
      },
    },
    defaultVariants: {
      size: 'md',
      tone: 'default',
    },
  }
)

export type SpinnerVariants = VariantProps<typeof spinnerVariants>

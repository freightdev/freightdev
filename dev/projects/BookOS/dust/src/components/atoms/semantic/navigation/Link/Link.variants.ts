import { cva, type VariantProps } from 'class-variance-authority'

export const linkVariants = cva(
  'transition-colors underline-offset-4 hover:underline focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
  {
    variants: {
      variant: {
        default: 'text-primary',
        subtle: 'text-muted-foreground',
        destructive: 'text-red-600 hover:text-red-700',
      },
      size: {
        sm: 'text-sm',
        md: 'text-base',
        lg: 'text-lg font-semibold',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'md',
    },
  }
)

export type LinkVariants = VariantProps<typeof linkVariants>

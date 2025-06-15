import { cva, type VariantProps } from 'class-variance-authority'

export const skeletonVariants = cva(
  'animate-pulse rounded-md bg-muted',
  {
    variants: {
      shape: {
        square: 'rounded-md',
        pill: 'rounded-full',
        none: '',
      },
      size: {
        sm: 'h-4 w-16',
        md: 'h-5 w-32',
        lg: 'h-6 w-48',
        full: 'h-full w-full',
      },
    },
    defaultVariants: {
      shape: 'square',
      size: 'md',
    },
  }
)

export type SkeletonVariants = VariantProps<typeof skeletonVariants>

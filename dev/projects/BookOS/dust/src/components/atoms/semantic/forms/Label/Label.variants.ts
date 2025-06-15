import { cva, type VariantProps } from 'class-variance-authority'

export const labelVariants = cva(
  'block font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70',
  {
    variants: {
      size: {
        sm: 'text-xs',
        md: 'text-sm',
        lg: 'text-base',
      },
    },
    defaultVariants: {
      size: 'md',
    },
  }
)

export type LabelVariants = VariantProps<typeof labelVariants>

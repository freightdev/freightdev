import { cva, type VariantProps } from 'class-variance-authority'

export const tableVariants = cva(
  'w-full border-collapse text-sm',
  {
    variants: {
      tone: {
        default: 'text-foreground',
        muted: 'text-muted-foreground',
        subtle: 'text-gray-600',
      },
      shadow: {
        none: '',
        sm: 'shadow-sm',
        md: 'shadow-md',
        lg: 'shadow-lg',
      },
      border: {
        none: '',
        outer: 'border border-border',
        inner: 'divide-y divide-border',
        both: 'border border-border divide-y divide-border',
      },
      rounded: {
        none: '',
        sm: 'rounded-sm',
        md: 'rounded-md',
        lg: 'rounded-lg',
      },
    },
    defaultVariants: {
      tone: 'default',
      shadow: 'none',
      border: 'outer',
      rounded: 'sm',
    },
  }
)

export type TableVariants = VariantProps<typeof tableVariants>

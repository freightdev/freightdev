import { cva, type VariantProps } from 'class-variance-authority'

export const selectVariants = cva(
  'flex w-full rounded-md border bg-transparent px-3 py-2 text-sm shadow-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
  {
    variants: {
      size: {
        sm: 'h-8 text-sm',
        md: 'h-10 text-sm',
        lg: 'h-12 text-base',
      },
      variant: {
        default: 'border-input text-foreground placeholder:text-muted-foreground',
        destructive: 'border-red-600 text-red-900 placeholder:text-red-400',
      },
    },
    defaultVariants: {
      size: 'md',
      variant: 'default',
    },
  }
)

export type SelectVariants = VariantProps<typeof selectVariants>

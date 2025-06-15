import { cva, type VariantProps } from 'class-variance-authority'

export const searchVariants = cva('block w-full', {
  variants: {
    size: {
      sm: 'text-sm px-2 py-1',
      md: 'text-base px-3 py-2',
      lg: 'text-lg px-4 py-3',
    },
    radius: {
      none: 'rounded-none',
      sm: 'rounded-sm',
      md: 'rounded-md',
      lg: 'rounded-lg',
      full: 'rounded-full',
    },
    variant: {
      default: 'border border-input bg-background text-foreground',
      subtle: 'bg-muted text-muted-foreground border border-transparent',
      outline: 'border border-border bg-white',
    },
  },
  defaultVariants: {
    size: 'md',
    radius: 'md',
    variant: 'default',
  },
})

export type SearchVariants = VariantProps<typeof searchVariants>

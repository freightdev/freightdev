import { cva, type VariantProps } from 'class-variance-authority'

export const paginationVariants = cva(
  'inline-flex items-center justify-center transition-colors select-none',
  {
    variants: {
      size: {
        sm: 'h-6 w-6 text-xs',
        md: 'h-8 w-8 text-sm',
        lg: 'h-10 w-10 text-base',
      },
      tone: {
        default: 'text-muted-foreground hover:text-foreground',
        active: 'bg-primary text-primary-foreground font-semibold',
        disabled: 'opacity-50 pointer-events-none',
      },
      rounded: {
        none: '',
        sm: 'rounded-sm',
        md: 'rounded-md',
        full: 'rounded-full',
      },
    },
    defaultVariants: {
      size: 'md',
      tone: 'default',
      rounded: 'md',
    },
  }
)

export type PaginationVariants = VariantProps<typeof paginationVariants>

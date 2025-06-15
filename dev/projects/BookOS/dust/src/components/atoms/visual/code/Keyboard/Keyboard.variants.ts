import { cva, type VariantProps } from 'class-variance-authority'

export const keyboardVariants = cva(
  'inline-flex items-center justify-center font-mono border bg-muted text-muted-foreground',
  {
    variants: {
      size: {
        sm: 'text-xs px-1.5 py-0.5',
        md: 'text-sm px-2 py-1',
        lg: 'text-base px-3 py-1.5',
      },
      tone: {
        default: 'border-border bg-muted text-foreground',
        subtle: 'border-transparent bg-muted text-muted-foreground',
        inverted: 'border-foreground bg-foreground text-background',
      },
      rounded: {
        none: '',
        sm: 'rounded-sm',
        md: 'rounded-md',
        lg: 'rounded-lg',
      },
    },
    defaultVariants: {
      size: 'sm',
      tone: 'default',
      rounded: 'sm',
    },
  }
)

export type KeyboardVariants = VariantProps<typeof keyboardVariants>

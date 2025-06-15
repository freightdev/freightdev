import { cva, type VariantProps } from 'class-variance-authority'

export const legendVariants = cva(
  'text-sm font-medium px-1',
  {
    variants: {
      tone: {
        default: 'text-foreground',
        muted: 'text-muted-foreground',
        destructive: 'text-red-600',
      },
      size: {
        sm: 'text-xs',
        md: 'text-sm',
        lg: 'text-base',
      },
    },
    defaultVariants: {
      tone: 'default',
      size: 'md',
    },
  }
)

export type LegendVariants = VariantProps<typeof legendVariants>

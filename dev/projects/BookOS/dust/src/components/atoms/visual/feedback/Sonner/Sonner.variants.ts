import { cva, type VariantProps } from 'class-variance-authority'

export const sonnerVariants = cva(
  'w-full max-w-sm flex items-start gap-3 p-4 border shadow-md rounded-md',
  {
    variants: {
      tone: {
        default: 'bg-background text-foreground border-border',
        success: 'bg-green-50 text-green-800 border-green-200',
        error: 'bg-red-50 text-red-800 border-red-200',
        warning: 'bg-yellow-50 text-yellow-900 border-yellow-200',
        info: 'bg-blue-50 text-blue-800 border-blue-200',
      },
      shadow: {
        none: '',
        sm: 'shadow-sm',
        md: 'shadow-md',
        lg: 'shadow-lg',
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
      shadow: 'md',
      rounded: 'md',
    },
  }
)

export type SonnerVariants = VariantProps<typeof sonnerVariants>

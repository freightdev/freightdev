import { cva, type VariantProps } from 'class-variance-authority'

export const alertVariants = cva(
  'w-full flex items-start gap-3 p-4 text-sm border',
  {
    variants: {
      tone: {
        default: 'bg-muted text-muted-foreground border-border',
        info: 'bg-blue-50 text-blue-800 border-blue-200',
        success: 'bg-green-50 text-green-800 border-green-200',
        warning: 'bg-yellow-50 text-yellow-900 border-yellow-300',
        danger: 'bg-red-50 text-red-800 border-red-200',
      },
      rounded: {
        none: '',
        sm: 'rounded-sm',
        md: 'rounded-md',
        lg: 'rounded-lg',
      },
      shadow: {
        none: '',
        sm: 'shadow-sm',
        md: 'shadow-md',
        lg: 'shadow-lg',
      },
    },
    defaultVariants: {
      tone: 'default',
      rounded: 'md',
      shadow: 'none',
    },
  }
)

export type AlertVariants = VariantProps<typeof alertVariants>

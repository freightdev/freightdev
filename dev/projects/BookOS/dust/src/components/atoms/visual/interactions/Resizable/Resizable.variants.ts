import { cva, type VariantProps } from 'class-variance-authority'

export const resizableVariants = cva(
  'relative flex overflow-hidden isolate group',
  {
    variants: {
      direction: {
        x: 'flex-row',
        y: 'flex-col',
      },
      border: {
        none: '',
        default: 'border border-border',
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
      direction: 'x',
      border: 'default',
      shadow: 'none',
      rounded: 'md',
    },
  }
)

export type ResizableVariants = VariantProps<typeof resizableVariants>

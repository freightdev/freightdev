import { cva, type VariantProps } from 'class-variance-authority'

export const popoverVariants = cva(
  'z-50 border bg-popover text-popover-foreground',
  {
    variants: {
      size: {
        sm: 'w-48 p-2 text-sm',
        md: 'w-64 p-3 text-sm',
        lg: 'w-80 p-4 text-base',
      },
      tone: {
        default: 'bg-white border-gray-200 text-black',
        muted: 'bg-muted border border-border text-muted-foreground',
        dark: 'bg-gray-900 text-white border-gray-700',
      },
      rounded: {
        sm: 'rounded-sm',
        md: 'rounded-md',
        lg: 'rounded-lg',
      },
      shadow: {
        sm: 'shadow-sm',
        md: 'shadow-md',
        lg: 'shadow-lg',
        none: 'shadow-none',
      },
    },
    defaultVariants: {
      size: 'md',
      tone: 'default',
      rounded: 'md',
      shadow: 'md',
    },
  }
)

export type PopoverVariants = VariantProps<typeof popoverVariants>

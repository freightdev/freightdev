import { cva, type VariantProps } from 'class-variance-authority'

export const sheetVariants = cva(
  'fixed z-50 bg-background text-foreground transition-all ease-in-out overflow-y-auto',
  {
    variants: {
      position: {
        left: 'inset-y-0 left-0 w-80',
        right: 'inset-y-0 right-0 w-80',
        top: 'inset-x-0 top-0 h-1/2',
        bottom: 'inset-x-0 bottom-0 h-1/2',
      },
      tone: {
        default: 'bg-white text-black',
        dark: 'bg-gray-900 text-white',
        muted: 'bg-muted text-muted-foreground',
      },
      size: {
        sm: 'max-w-sm',
        md: 'max-w-md',
        lg: 'max-w-lg',
      },
      rounded: {
        none: '',
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
      position: 'right',
      tone: 'default',
      size: 'md',
      rounded: 'md',
      shadow: 'md',
    },
  }
)

export type SheetVariants = VariantProps<typeof sheetVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const scrollAreaVariants = cva(
  'overflow-auto scrollbar-thin scrollbar-thumb-rounded',
  {
    variants: {
      size: {
        sm: 'max-h-40',
        md: 'max-h-60',
        lg: 'max-h-96',
        full: 'h-full',
      },
      radius: {
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
      scrollbarVisibility: {
        visible: 'scrollbar-thumb-gray-400 scrollbar-track-gray-100',
        subtle: 'scrollbar-thumb-muted scrollbar-track-transparent',
        hidden: 'scrollbar-none',
      },
    },
    defaultVariants: {
      size: 'md',
      radius: 'md',
      shadow: 'none',
      scrollbarVisibility: 'visible',
    },
  }
)

export type ScrollAreaVariants = VariantProps<typeof scrollAreaVariants>

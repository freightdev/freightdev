import { cva, type VariantProps } from 'class-variance-authority'

export const tabVariants = cva(
  'inline-flex items-center justify-center whitespace-nowrap px-3 py-1.5 transition-colors text-sm',
  {
    variants: {
      tone: {
        default: 'text-muted-foreground hover:text-foreground',
        active: 'text-primary border-b-2 border-primary',
        danger: 'text-red-500 hover:text-red-700',
      },
      size: {
        sm: 'text-xs py-1 px-2',
        md: 'text-sm py-1.5 px-3',
        lg: 'text-base py-2 px-4',
      },
      align: {
        left: 'justify-start',
        center: 'justify-center',
        right: 'justify-end',
      },
      rounded: {
        none: '',
        sm: 'rounded-sm',
        md: 'rounded-md',
        full: 'rounded-full',
      },
      disabled: {
        true: 'opacity-50 pointer-events-none',
        false: '',
      },
    },
    defaultVariants: {
      tone: 'default',
      size: 'md',
      align: 'center',
      rounded: 'none',
      disabled: false,
    },
  }
)

export type TabVariants = VariantProps<typeof tabVariants>

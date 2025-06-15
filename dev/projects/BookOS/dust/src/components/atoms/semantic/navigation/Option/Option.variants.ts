import { cva, type VariantProps } from 'class-variance-authority'

export const optionVariants = cva('', {
  variants: {
    tone: {
      default: '',
      muted: 'text-muted-foreground',
      accent: 'text-primary',
      danger: 'text-red-600',
    },
    size: {
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
    },
    state: {
      enabled: '',
      disabled: 'opacity-50 cursor-not-allowed',
    },
  },
  defaultVariants: {
    tone: 'default',
    size: 'md',
    state: 'enabled',
  },
})

export type OptionVariants = VariantProps<typeof optionVariants>

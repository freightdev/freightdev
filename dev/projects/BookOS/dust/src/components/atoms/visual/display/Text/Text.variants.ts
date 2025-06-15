import { cva, type VariantProps } from 'class-variance-authority'

export const textVariants = cva('', {
  variants: {
    size: {
      xs: 'text-xs',
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
      xl: 'text-xl',
    },
    weight: {
      light: 'font-light',
      normal: 'font-normal',
      medium: 'font-medium',
      semibold: 'font-semibold',
      bold: 'font-bold',
    },
    tone: {
      default: 'text-foreground',
      muted: 'text-muted-foreground',
      destructive: 'text-red-600',
    },
  },
  defaultVariants: {
    size: 'md',
    weight: 'normal',
    tone: 'default',
  },
})

export type TextVariants = VariantProps<typeof textVariants>

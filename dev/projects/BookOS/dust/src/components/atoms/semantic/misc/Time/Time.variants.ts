import { cva, type VariantProps } from 'class-variance-authority'

export const timeVariants = cva('', {
  variants: {
    tone: {
      default: 'text-foreground',
      muted: 'text-muted-foreground',
      accent: 'text-primary',
      subtle: 'text-gray-500',
    },
    size: {
      xs: 'text-xs',
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
    },
    weight: {
      normal: 'font-normal',
      medium: 'font-medium',
      bold: 'font-bold',
    },
  },
  defaultVariants: {
    tone: 'muted',
    size: 'sm',
    weight: 'normal',
  },
})

export type TimeVariants = VariantProps<typeof timeVariants>

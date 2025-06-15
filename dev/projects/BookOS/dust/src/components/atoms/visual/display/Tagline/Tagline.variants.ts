import { cva, type VariantProps } from 'class-variance-authority'

export const taglineVariants = cva('tracking-wider uppercase', {
  variants: {
    tone: {
      default: 'text-muted-foreground',
      subtle: 'text-gray-400',
      accent: 'text-primary',
    },
    size: {
      sm: 'text-xs',
      md: 'text-sm',
      lg: 'text-base',
    },
    weight: {
      normal: 'font-normal',
      medium: 'font-medium',
      bold: 'font-bold',
    },
    align: {
      left: 'text-left',
      center: 'text-center',
      right: 'text-right',
    },
  },
  defaultVariants: {
    tone: 'default',
    size: 'sm',
    weight: 'medium',
    align: 'left',
  },
})

export type TaglineVariants = VariantProps<typeof taglineVariants>

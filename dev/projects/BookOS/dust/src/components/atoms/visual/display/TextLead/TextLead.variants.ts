import { cva, type VariantProps } from 'class-variance-authority'

export const textLeadVariants = cva('max-w-prose text-balance', {
  variants: {
    size: {
      sm: 'text-sm leading-relaxed',
      md: 'text-base leading-loose',
      lg: 'text-lg leading-loose',
    },
    tone: {
      default: 'text-muted-foreground',
      accent: 'text-primary',
      subtle: 'text-gray-500',
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
    size: 'md',
    tone: 'default',
    weight: 'normal',
    align: 'left',
  },
})

export type TextLeadVariants = VariantProps<typeof textLeadVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const labelIconVariants = cva('inline-flex items-center', {
  variants: {
    size: {
      sm: 'text-xs',
      md: 'text-sm',
      lg: 'text-base',
    },
    tone: {
      default: 'text-foreground',
      muted: 'text-muted-foreground',
      accent: 'text-primary',
      danger: 'text-red-600',
    },
    weight: {
      normal: 'font-normal',
      medium: 'font-medium',
      bold: 'font-bold',
    },
    gap: {
      sm: 'gap-1',
      md: 'gap-2',
      lg: 'gap-3',
    },
  },
  defaultVariants: {
    size: 'md',
    tone: 'default',
    weight: 'medium',
    gap: 'sm',
  },
})

export type LabelIconVariants = VariantProps<typeof labelIconVariants>

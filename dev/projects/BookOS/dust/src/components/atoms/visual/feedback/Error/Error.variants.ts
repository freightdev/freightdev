import { cva, type VariantProps } from 'class-variance-authority'

export const errorVariants = cva('flex items-start gap-1.5', {
  variants: {
    tone: {
      default: 'text-red-600',
      muted: 'text-muted-foreground',
    },
    size: {
      sm: 'text-xs',
      md: 'text-sm',
      lg: 'text-base',
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
    align: 'left',
  },
})

export type ErrorVariants = VariantProps<typeof errorVariants>

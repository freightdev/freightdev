import { cva, type VariantProps } from 'class-variance-authority'

export const datalistVariants = cva('', {
  variants: {
    size: {
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
    },
    tone: {
      default: '',
      muted: 'text-muted-foreground',
      accent: 'text-primary',
    },
  },
  defaultVariants: {
    size: 'md',
    tone: 'default',
  },
})

export type DatalistVariants = VariantProps<typeof datalistVariants>

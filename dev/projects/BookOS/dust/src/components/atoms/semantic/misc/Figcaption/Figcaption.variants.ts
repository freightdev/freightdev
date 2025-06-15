import { cva, type VariantProps } from 'class-variance-authority'

export const figcaptionVariants = cva('text-sm', {
  variants: {
    tone: {
      default: 'text-foreground',
      muted: 'text-muted-foreground',
      accent: 'text-primary',
    },
    align: {
      left: 'text-left',
      center: 'text-center',
      right: 'text-right',
    },
    size: {
      xs: 'text-xs',
      sm: 'text-sm',
      md: 'text-base',
    },
  },
  defaultVariants: {
    tone: 'muted',
    align: 'center',
    size: 'sm',
  },
})

export type FigcaptionVariants = VariantProps<typeof figcaptionVariants>

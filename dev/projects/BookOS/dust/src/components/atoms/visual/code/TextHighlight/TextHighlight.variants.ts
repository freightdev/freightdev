import { cva, type VariantProps } from 'class-variance-authority'

export const textHighlightVariants = cva('inline', {
  variants: {
    tone: {
      default: 'bg-yellow-200 text-black',
      muted: 'bg-muted text-foreground',
      accent: 'bg-primary/20 text-primary',
      danger: 'bg-red-100 text-red-600',
    },
    size: {
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
    },
    weight: {
      normal: 'font-normal',
      medium: 'font-medium',
      bold: 'font-bold',
    },
    style: {
      solid: '',
      underline: 'underline underline-offset-2',
      italic: 'italic',
    },
  },
  defaultVariants: {
    tone: 'default',
    size: 'md',
    weight: 'medium',
    style: 'solid',
  },
})

export type TextHighlightVariants = VariantProps<typeof textHighlightVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const blockquoteVariants = cva('relative pl-4 border-l-4', {
  variants: {
    tone: {
      default: 'border-border text-foreground',
      muted: 'border-muted text-muted-foreground',
      info: 'border-blue-500 text-blue-900',
      danger: 'border-red-500 text-red-800',
      success: 'border-green-500 text-green-900',
    },
    size: {
      sm: 'text-sm leading-snug',
      md: 'text-base leading-normal',
      lg: 'text-lg leading-relaxed',
    },
    weight: {
      normal: 'font-normal',
      medium: 'font-medium',
      bold: 'font-bold',
    },
    accent: {
      none: '',
      italic: 'italic',
      underline: 'underline underline-offset-2',
    },
  },
  defaultVariants: {
    tone: 'default',
    size: 'md',
    weight: 'normal',
    accent: 'none',
  },
})

export type BlockquoteVariants = VariantProps<typeof blockquoteVariants>

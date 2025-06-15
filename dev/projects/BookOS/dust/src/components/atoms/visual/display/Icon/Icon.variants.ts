import { cva, type VariantProps } from 'class-variance-authority'

export const iconVariants = cva('inline-block', {
  variants: {
    size: {
      xs: 'h-3 w-3',
      sm: 'h-4 w-4',
      md: 'h-5 w-5',
      lg: 'h-6 w-6',
      xl: 'h-8 w-8',
    },
    tone: {
      default: 'text-foreground',
      muted: 'text-muted-foreground',
      destructive: 'text-red-600',
    },
  },
  defaultVariants: {
    size: 'md',
    tone: 'default',
  },
})

export type IconVariants = VariantProps<typeof iconVariants>

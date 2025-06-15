import { cva, type VariantProps } from 'class-variance-authority'

export const loadingDotsVariants = cva('flex items-center gap-1', {
  variants: {
    size: {
      xs: 'h-1 w-1',
      sm: 'h-1.5 w-1.5',
      md: 'h-2 w-2',
      lg: 'h-2.5 w-2.5',
    },
    tone: {
      default: 'bg-muted-foreground',
      primary: 'bg-primary',
      destructive: 'bg-red-500',
    },
  },
  defaultVariants: {
    size: 'md',
    tone: 'default',
  },
})

export type LoadingDotsVariants = VariantProps<typeof loadingDotsVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const menuVariants = cva('list-none', {
  variants: {
    orientation: {
      vertical: 'flex flex-col',
      horizontal: 'flex flex-row',
    },
    size: {
      sm: 'text-sm gap-1',
      md: 'text-base gap-2',
      lg: 'text-lg gap-3',
    },
    tone: {
      default: '',
      muted: 'text-muted-foreground',
      accent: 'text-primary',
    },
  },
  defaultVariants: {
    orientation: 'vertical',
    size: 'md',
    tone: 'default',
  },
})

export type MenuVariants = VariantProps<typeof menuVariants>

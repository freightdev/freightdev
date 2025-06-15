import { cva, type VariantProps } from 'class-variance-authority'

export const statusDotVariants = cva('inline-block rounded-full', {
  variants: {
    size: {
      xs: 'h-1.5 w-1.5',
      sm: 'h-2 w-2',
      md: 'h-2.5 w-2.5',
      lg: 'h-3 w-3',
    },
    tone: {
      online: 'bg-green-500',
      offline: 'bg-gray-400',
      busy: 'bg-red-500',
      idle: 'bg-yellow-400',
      neutral: 'bg-muted-foreground',
    },
    glow: {
      true: 'shadow-md shadow-current',
      false: '',
    },
  },
  defaultVariants: {
    size: 'sm',
    tone: 'neutral',
    glow: false,
  },
})

export type StatusDotVariants = VariantProps<typeof statusDotVariants>

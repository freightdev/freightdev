import { cva, type VariantProps } from 'class-variance-authority'

export const figureVariants = cva('w-full', {
  variants: {
    align: {
      left: 'text-left',
      center: 'text-center',
      right: 'text-right',
    },
    padding: {
      none: '',
      sm: 'p-2',
      md: 'p-4',
      lg: 'p-6',
    },
  },
  defaultVariants: {
    align: 'center',
    padding: 'md',
  },
})

export type FigureVariants = VariantProps<typeof figureVariants>

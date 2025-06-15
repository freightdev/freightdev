import { cva, type VariantProps } from 'class-variance-authority'

export const articleVariants = cva('w-full prose', {
  variants: {
    spacing: {
      none: '',
      sm: 'py-4',
      md: 'py-6',
      lg: 'py-8',
    },
    width: {
      full: 'max-w-none',
      narrow: 'max-w-prose',
      wide: 'max-w-4xl',
    },
    align: {
      left: 'mx-0',
      center: 'mx-auto',
    },
  },
  defaultVariants: {
    spacing: 'md',
    width: 'narrow',
    align: 'center',
  },
})

export type ArticleVariants = VariantProps<typeof articleVariants>

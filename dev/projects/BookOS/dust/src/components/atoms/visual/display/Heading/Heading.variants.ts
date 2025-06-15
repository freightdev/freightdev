import { cva, type VariantProps } from 'class-variance-authority'

export const headingVariants = cva('font-semibold leading-snug', {
  variants: {
    level: {
      h1: 'text-4xl',
      h2: 'text-3xl',
      h3: 'text-2xl',
      h4: 'text-xl',
      h5: 'text-lg',
      h6: 'text-base',
    },
    tone: {
      default: 'text-foreground',
      muted: 'text-muted-foreground',
      accent: 'text-primary',
    },
    spacing: {
      none: '',
      sm: 'mb-1',
      md: 'mb-2',
      lg: 'mb-4',
    },
  },
  defaultVariants: {
    level: 'h2',
    tone: 'default',
    spacing: 'md',
  },
})

export type HeadingVariants = VariantProps<typeof headingVariants>

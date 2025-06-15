import { cva, type VariantProps } from 'class-variance-authority'

export const footerVariants = cva('w-full', {
  variants: {
    padding: {
      none: '',
      sm: 'px-4 py-2',
      md: 'px-6 py-4',
      lg: 'px-8 py-6',
    },
    border: {
      none: '',
      top: 'border-t border-border',
    },
    bg: {
      none: '',
      muted: 'bg-muted',
      white: 'bg-white',
      dark: 'bg-gray-900 text-white',
    },
  },
  defaultVariants: {
    padding: 'md',
    border: 'top',
    bg: 'muted',
  },
})

export type FooterVariants = VariantProps<typeof footerVariants>

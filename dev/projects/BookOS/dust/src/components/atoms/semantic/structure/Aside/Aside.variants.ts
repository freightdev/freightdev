import { cva, type VariantProps } from 'class-variance-authority'

export const asideVariants = cva('w-full', {
  variants: {
    width: {
      sm: 'max-w-xs',
      md: 'max-w-sm',
      lg: 'max-w-md',
      xl: 'max-w-lg',
    },
    position: {
      static: '',
      sticky: 'sticky top-6',
      fixed: 'fixed top-0',
    },
    padding: {
      none: '',
      sm: 'p-2',
      md: 'p-4',
      lg: 'p-6',
    },
    bg: {
      none: '',
      muted: 'bg-muted',
      white: 'bg-white',
      dark: 'bg-gray-900 text-white',
    },
  },
  defaultVariants: {
    width: 'md',
    position: 'static',
    padding: 'md',
    bg: 'none',
  },
})

export type AsideVariants = VariantProps<typeof asideVariants>

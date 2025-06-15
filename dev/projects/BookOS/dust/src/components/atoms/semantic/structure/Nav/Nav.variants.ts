import { cva, type VariantProps } from 'class-variance-authority'

export const navVariants = cva('w-full flex items-center justify-between', {
  variants: {
    position: {
      static: 'static',
      sticky: 'sticky top-0 z-50 backdrop-blur-md',
      fixed: 'fixed top-0 left-0 w-full z-50',
    },
    padding: {
      none: '',
      sm: 'px-4 py-2',
      md: 'px-6 py-3',
      lg: 'px-8 py-4',
    },
    bg: {
      none: '',
      white: 'bg-white',
      dark: 'bg-gray-900 text-white',
      translucent: 'bg-white/80 dark:bg-gray-900/80',
    },
    border: {
      none: '',
      bottom: 'border-b border-border',
    },
  },
  defaultVariants: {
    position: 'sticky',
    padding: 'md',
    bg: 'white',
    border: 'bottom',
  },
})

export type NavVariants = VariantProps<typeof navVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const headerVariants = cva('w-full flex items-center', {
  variants: {
    padding: {
      none: '',
      sm: 'px-4 py-2',
      md: 'px-6 py-3',
      lg: 'px-8 py-4',
    },
    shadow: {
      none: '',
      sm: 'shadow-sm',
      md: 'shadow-md',
      lg: 'shadow-lg',
    },
    border: {
      none: '',
      bottom: 'border-b border-border',
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
    shadow: 'none',
    border: 'bottom',
    bg: 'white',
  },
})

export type HeaderVariants = VariantProps<typeof headerVariants>

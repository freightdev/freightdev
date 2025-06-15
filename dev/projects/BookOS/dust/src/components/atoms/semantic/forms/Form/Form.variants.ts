import { cva, type VariantProps } from 'class-variance-authority'

export const formVariants = cva('w-full flex flex-col', {
  variants: {
    padding: {
      none: '',
      sm: 'p-2',
      md: 'p-4',
      lg: 'p-6',
    },
    spacing: {
      none: 'space-y-0',
      sm: 'space-y-2',
      md: 'space-y-4',
      lg: 'space-y-6',
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
    spacing: 'md',
    bg: 'none',
  },
})

export type FormVariants = VariantProps<typeof formVariants>

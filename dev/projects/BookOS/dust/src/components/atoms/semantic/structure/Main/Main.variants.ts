import { cva, type VariantProps } from 'class-variance-authority'

export const mainVariants = cva('w-full flex flex-col grow', {
  variants: {
    padding: {
      none: '',
      sm: 'px-4 py-2',
      md: 'px-6 py-4',
      lg: 'px-8 py-6',
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
    bg: 'none',
  },
})

export type MainVariants = VariantProps<typeof mainVariants>

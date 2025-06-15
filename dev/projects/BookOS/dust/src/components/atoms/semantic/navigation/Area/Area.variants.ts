import { cva, type VariantProps } from 'class-variance-authority'

export const areaVariants = cva('', {
  variants: {
    size: {
      sm: 'p-2',
      md: 'p-4',
      lg: 'p-6',
      full: 'p-0',
    },
    bg: {
      none: '',
      white: 'bg-white',
      dark: 'bg-gray-900 text-white',
      muted: 'bg-muted',
    },
    border: {
      none: '',
      default: 'border',
      muted: 'border border-muted',
    },
  },
  defaultVariants: {
    size: 'md',
    bg: 'none',
    border: 'none',
  },
})

export type AreaVariants = VariantProps<typeof areaVariants>

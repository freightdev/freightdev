import { cva, type VariantProps } from 'class-variance-authority'

export const canvasVariants = cva('', {
  variants: {
    size: {
      sm: 'w-32 h-32',
      md: 'w-64 h-64',
      lg: 'w-96 h-96',
      full: 'w-full h-full',
    },
    bg: {
      none: '',
      white: 'bg-white',
      dark: 'bg-black',
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

export type CanvasVariants = VariantProps<typeof canvasVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const shellVariants = cva('relative w-full', {
  variants: {
    maxWidth: {
      none: '',
      sm: 'max-w-screen-sm',
      md: 'max-w-screen-md',
      lg: 'max-w-screen-lg',
      xl: 'max-w-screen-xl',
      '2xl': 'max-w-screen-2xl',
    },
    padding: {
      none: '',
      sm: 'px-4',
      md: 'px-6',
      lg: 'px-8',
    },
    center: {
      false: '',
      true: 'mx-auto',
    },
  },
  defaultVariants: {
    maxWidth: 'xl',
    padding: 'md',
    center: true,
  },
})

export type ShellVariants = VariantProps<typeof shellVariants>

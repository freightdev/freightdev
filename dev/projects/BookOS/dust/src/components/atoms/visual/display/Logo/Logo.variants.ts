import { cva, type VariantProps } from 'class-variance-authority'

export const logoVariants = cva('inline-flex items-center font-bold', {
  variants: {
    size: {
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
      xl: 'text-xl',
    },
    style: {
      text: '',
      outlined: 'tracking-wide uppercase',
      mono: 'font-mono',
    },
    align: {
      left: 'justify-start',
      center: 'justify-center',
      right: 'justify-end',
    },
    gap: {
      sm: 'gap-1',
      md: 'gap-2',
      lg: 'gap-3',
    },
  },
  defaultVariants: {
    size: 'md',
    style: 'text',
    align: 'left',
    gap: 'md',
  },
})

export type LogoVariants = VariantProps<typeof logoVariants>

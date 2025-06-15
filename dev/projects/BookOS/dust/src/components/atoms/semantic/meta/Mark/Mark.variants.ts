import { cva, type VariantProps } from 'class-variance-authority'

export const markVariants = cva('inline', {
  variants: {
    color: {
      yellow: 'bg-yellow-200 text-black',
      blue: 'bg-blue-200 text-blue-900',
      red: 'bg-red-200 text-red-900',
      green: 'bg-green-200 text-green-900',
    },
    weight: {
      normal: 'font-normal',
      medium: 'font-medium',
      bold: 'font-bold',
    },
    size: {
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
    },
  },
  defaultVariants: {
    color: 'yellow',
    weight: 'normal',
    size: 'md',
  },
})

export type MarkVariants = VariantProps<typeof markVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const svgVariants = cva('', {
  variants: {
    size: {
      sm: 'w-4 h-4',
      md: 'w-6 h-6',
      lg: 'w-8 h-8',
      xl: 'w-10 h-10',
    },
    color: {
      current: 'fill-current',
      muted: 'fill-muted',
      primary: 'fill-primary',
      white: 'fill-white',
    },
    stroke: {
      default: 'stroke-[1.5]',
      light: 'stroke-[1]',
      heavy: 'stroke-2',
    },
  },
  defaultVariants: {
    size: 'md',
    color: 'current',
    stroke: 'default',
  },
})

export type SvgVariants = VariantProps<typeof svgVariants>

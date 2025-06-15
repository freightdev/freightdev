import { cva, type VariantProps } from 'class-variance-authority'

export const titleVariants = cva('font-bold leading-tight', {
  variants: {
    size: {
      xs: 'text-sm',
      sm: 'text-base',
      md: 'text-xl',
      lg: 'text-2xl',
      xl: 'text-4xl',
      '2xl': 'text-5xl',
    },
    tone: {
      default: 'text-foreground',
      muted: 'text-muted-foreground',
      accent: 'text-primary',
      danger: 'text-red-600',
    },
    align: {
      left: 'text-left',
      center: 'text-center',
      right: 'text-right',
    },
    casing: {
      normal: '',
      uppercase: 'uppercase',
      capitalize: 'capitalize',
    },
  },
  defaultVariants: {
    size: 'xl',
    tone: 'default',
    align: 'left',
    casing: 'normal',
  },
})

export type TitleVariants = VariantProps<typeof titleVariants>

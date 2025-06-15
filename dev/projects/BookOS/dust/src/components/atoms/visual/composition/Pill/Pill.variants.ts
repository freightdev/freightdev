import { cva, type VariantProps } from 'class-variance-authority'

export const pillVariants = cva(
  'inline-flex items-center justify-center whitespace-nowrap px-2',
  {
    variants: {
      tone: {
        default: 'bg-muted text-muted-foreground',
        primary: 'bg-primary text-primary-foreground',
        success: 'bg-green-500 text-white',
        warning: 'bg-yellow-400 text-black',
        danger: 'bg-red-500 text-white',
      },
      size: {
        sm: 'text-xs h-5',
        md: 'text-sm h-6',
        lg: 'text-base h-7',
      },
      weight: {
        normal: 'font-normal',
        medium: 'font-medium',
        bold: 'font-bold',
      },
      rounded: {
        sm: 'rounded-sm',
        md: 'rounded-md',
        full: 'rounded-full',
      },
      style: {
        solid: '',
        outline: 'bg-transparent border',
      },
    },
    compoundVariants: [
      {
        style: 'outline',
        tone: 'primary',
        className: 'border-primary text-primary',
      },
      {
        style: 'outline',
        tone: 'danger',
        className: 'border-red-500 text-red-500',
      },
      {
        style: 'outline',
        tone: 'success',
        className: 'border-green-500 text-green-600',
      },
    ],
    defaultVariants: {
      tone: 'default',
      size: 'md',
      weight: 'medium',
      rounded: 'full',
      style: 'solid',
    },
  }
)

export type PillVariants = VariantProps<typeof pillVariants>

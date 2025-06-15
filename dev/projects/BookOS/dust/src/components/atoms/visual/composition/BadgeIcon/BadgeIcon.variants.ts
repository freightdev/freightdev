import { cva, type VariantProps } from 'class-variance-authority'

export const badgeIconVariants = cva(
  'absolute rounded-full z-10 ring-2',
  {
    variants: {
      tone: {
        default: 'bg-muted-foreground',
        info: 'bg-blue-500',
        success: 'bg-green-500',
        warning: 'bg-yellow-400',
        error: 'bg-red-500',
      },
      size: {
        xs: 'h-1.5 w-1.5',
        sm: 'h-2 w-2',
        md: 'h-2.5 w-2.5',
        lg: 'h-3 w-3',
      },
      position: {
        topRight: 'top-0 right-0 translate-x-1/2 -translate-y-1/2',
        topLeft: 'top-0 left-0 -translate-x-1/2 -translate-y-1/2',
        bottomRight: 'bottom-0 right-0 translate-x-1/2 translate-y-1/2',
        bottomLeft: 'bottom-0 left-0 -translate-x-1/2 translate-y-1/2',
        center: 'top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2',
      },
      border: {
        light: 'ring-white',
        dark: 'ring-black',
        none: 'ring-0',
      },
    },
    defaultVariants: {
      tone: 'default',
      size: 'sm',
      position: 'topRight',
      border: 'light',
    },
  }
)

export type BadgeIconVariants = VariantProps<typeof badgeIconVariants>

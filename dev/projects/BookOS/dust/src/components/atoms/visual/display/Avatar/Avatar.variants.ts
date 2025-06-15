import { cva, type VariantProps } from 'class-variance-authority'

export const avatarVariants = cva(
  'overflow-hidden bg-muted text-muted-foreground flex items-center justify-center',
  {
    variants: {
      size: {
        xs: 'h-6 w-6 text-xs',
        sm: 'h-8 w-8 text-sm',
        md: 'h-10 w-10 text-base',
        lg: 'h-12 w-12 text-lg',
        xl: 'h-16 w-16 text-xl',
      },
      shape: {
        circle: 'rounded-full',
        square: 'rounded-md',
      },
    },
    defaultVariants: {
      size: 'md',
      shape: 'circle',
    },
  }
)

export type AvatarVariants = VariantProps<typeof avatarVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const dividerVariants = cva('', {
  variants: {
    orientation: {
      horizontal: 'w-full h-px',
      vertical: 'h-full w-px',
    },
    tone: {
      default: 'bg-border',
      muted: 'bg-muted',
      destructive: 'bg-red-500',
    },
    thickness: {
      thin: '',
      medium: 'h-0.5 w-0.5',
      thick: 'h-1 w-1',
    },
  },
  compoundVariants: [
    {
      orientation: 'horizontal',
      thickness: 'medium',
      className: 'h-0.5',
    },
    {
      orientation: 'horizontal',
      thickness: 'thick',
      className: 'h-1',
    },
    {
      orientation: 'vertical',
      thickness: 'medium',
      className: 'w-0.5',
    },
    {
      orientation: 'vertical',
      thickness: 'thick',
      className: 'w-1',
    },
  ],
  defaultVariants: {
    orientation: 'horizontal',
    tone: 'default',
    thickness: 'thin',
  },
})

export type DividerVariants = VariantProps<typeof dividerVariants>

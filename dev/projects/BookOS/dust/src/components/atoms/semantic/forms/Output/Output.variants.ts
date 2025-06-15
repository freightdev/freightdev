import { cva, type VariantProps } from 'class-variance-authority'

export const outputVariants = cva('inline-block', {
  variants: {
    tone: {
      default: 'text-foreground',
      muted: 'text-muted-foreground',
      success: 'text-green-600',
      danger: 'text-red-600',
    },
    size: {
      sm: 'text-sm',
      md: 'text-base',
      lg: 'text-lg',
    },
    border: {
      none: '',
      default: 'border px-2 py-1 rounded',
      muted: 'border border-muted px-2 py-1 rounded',
    },
  },
  defaultVariants: {
    tone: 'default',
    size: 'md',
    border: 'none',
  },
})

export type OutputVariants = VariantProps<typeof outputVariants>

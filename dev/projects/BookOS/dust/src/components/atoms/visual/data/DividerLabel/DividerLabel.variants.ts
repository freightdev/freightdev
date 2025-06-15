import { cva, type VariantProps } from 'class-variance-authority'

export const dividerLabelVariants = cva('flex items-center w-full gap-2', {
  variants: {
    align: {
      left: 'justify-start',
      center: 'justify-center',
      right: 'justify-end',
    },
    tone: {
      default: 'text-muted-foreground border-border',
      accent: 'text-primary border-primary',
      danger: 'text-red-600 border-red-500',
    },
    size: {
      sm: 'text-xs',
      md: 'text-sm',
      lg: 'text-base',
    },
    lineStyle: {
      solid: 'border-t',
      dashed: 'border-t border-dashed',
      dotted: 'border-t border-dotted',
    },
  },
  defaultVariants: {
    align: 'center',
    tone: 'default',
    size: 'sm',
    lineStyle: 'solid',
  },
})

export type DividerLabelVariants = VariantProps<typeof dividerLabelVariants>

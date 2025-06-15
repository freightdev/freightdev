import { cva, type VariantProps } from 'class-variance-authority'

export const separatorVariants = cva('', {
  variants: {
    direction: {
      horizontal: 'w-full h-px',
      vertical: 'h-full w-px',
    },
    tone: {
      default: 'bg-border',
      muted: 'bg-muted',
      accent: 'bg-primary',
    },
    thickness: {
      sm: 'h-[1px] w-[1px]',
      md: '',
      lg: 'h-[3px] w-[3px]',
    },
    spacing: {
      none: '',
      sm: 'my-1',
      md: 'my-2',
      lg: 'my-4',
    },
    dashed: {
      true: 'border-0 border-t border-dashed',
      false: '',
    },
  },
  compoundVariants: [
    {
      direction: 'horizontal',
      dashed: true,
      className: 'w-full h-auto',
    },
    {
      direction: 'vertical',
      dashed: true,
      className: 'h-full w-auto',
    },
  ],
  defaultVariants: {
    direction: 'horizontal',
    tone: 'default',
    thickness: 'md',
    spacing: 'md',
    dashed: false,
  },
})

export type SeparatorVariants = VariantProps<typeof separatorVariants>

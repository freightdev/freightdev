import { cva, type VariantProps } from 'class-variance-authority'

export const fieldsetVariants = cva(
  'border-border rounded-md',
  {
    variants: {
      padding: {
        none: '',
        sm: 'p-2',
        md: 'p-4',
        lg: 'p-6',
      },
      border: {
        none: 'border-0',
        subtle: 'border',
        strong: 'border-2',
      },
      gap: {
        none: '',
        sm: 'gap-2',
        md: 'gap-4',
        lg: 'gap-6',
      },
    },
    defaultVariants: {
      padding: 'md',
      border: 'subtle',
      gap: 'md',
    },
  }
)

export type FieldsetVariants = VariantProps<typeof fieldsetVariants>

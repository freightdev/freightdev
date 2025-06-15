import { cva, type VariantProps } from 'class-variance-authority'

export const switchVariants = cva(
  'peer inline-flex h-5 w-9 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
  {
    variants: {
      variant: {
        default: 'bg-input data-[state=checked]:bg-primary',
        destructive: 'bg-input data-[state=checked]:bg-red-600',
      },
    },
    defaultVariants: {
      variant: 'default',
    },
  }
)

export type SwitchVariants = VariantProps<typeof switchVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const toggleVariants = cva(
  'inline-flex items-center justify-center transition-colors ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 data-[state=on]:bg-accent',
  {
    variants: {
      tone: {
        default: 'bg-muted text-muted-foreground data-[state=on]:bg-primary data-[state=on]:text-white',
        success: 'bg-muted text-green-600 data-[state=on]:bg-green-500 data-[state=on]:text-white',
        danger: 'bg-muted text-red-600 data-[state=on]:bg-red-500 data-[state=on]:text-white',
      },
      size: {
        sm: 'h-6 px-2 text-xs',
        md: 'h-8 px-3 text-sm',
        lg: 'h-10 px-4 text-base',
      },
      rounded: {
        none: '',
        sm: 'rounded-sm',
        md: 'rounded-md',
        full: 'rounded-full',
      },
    },
    defaultVariants: {
      tone: 'default',
      size: 'md',
      rounded: 'md',
    },
  }
)

export type ToggleVariants = VariantProps<typeof toggleVariants>

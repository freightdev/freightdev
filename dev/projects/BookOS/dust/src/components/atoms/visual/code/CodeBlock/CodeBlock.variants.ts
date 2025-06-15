import { cva, type VariantProps } from 'class-variance-authority'

export const codeBlockVariants = cva(
  'font-mono whitespace-pre break-words px-3 py-2 overflow-x-auto',
  {
    variants: {
      tone: {
        default: 'bg-muted text-muted-foreground',
        contrast: 'bg-black text-white',
        subtle: 'bg-muted text-xs text-muted',
      },
      size: {
        sm: 'text-xs',
        md: 'text-sm',
        lg: 'text-base',
      },
      rounded: {
        none: '',
        sm: 'rounded-sm',
        md: 'rounded-md',
        lg: 'rounded-lg',
      },
    },
    defaultVariants: {
      tone: 'default',
      size: 'sm',
      rounded: 'md',
    },
  }
)

export type CodeBlockVariants = VariantProps<typeof codeBlockVariants>

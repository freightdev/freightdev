import { cva, type VariantProps } from 'class-variance-authority'

export const sidebarVariants = cva(
  'flex flex-col h-full z-40 overflow-y-auto transition-colors',
  {
    variants: {
      position: {
        left: 'fixed left-0 top-0',
        right: 'fixed right-0 top-0',
        static: 'relative',
      },
      tone: {
        default: 'bg-muted text-foreground',
        dark: 'bg-gray-900 text-white',
        light: 'bg-white text-black',
      },
      size: {
        sm: 'w-48',
        md: 'w-64',
        lg: 'w-80',
      },
      border: {
        none: '',
        right: 'border-r border-border',
        left: 'border-l border-border',
      },
      shadow: {
        none: '',
        sm: 'shadow-sm',
        md: 'shadow-md',
        lg: 'shadow-lg',
      },
      rounded: {
        none: '',
        sm: 'rounded-sm',
        md: 'rounded-md',
        lg: 'rounded-lg',
      },
    },
    defaultVariants: {
      position: 'left',
      tone: 'default',
      size: 'md',
      border: 'right',
      shadow: 'md',
      rounded: 'none',
    },
  }
)

export type SidebarVariants = VariantProps<typeof sidebarVariants>

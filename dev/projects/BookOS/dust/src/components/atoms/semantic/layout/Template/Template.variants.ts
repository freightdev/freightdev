import { cva, type VariantProps } from 'class-variance-authority'

export const templateVariants = cva('', {
  variants: {
    padding: {
      none: '',
      sm: 'p-2',
      md: 'p-4',
      lg: 'p-6',
    },
    bg: {
      none: '',
      white: 'bg-white',
      muted: 'bg-muted',
      dark: 'bg-gray-900 text-white',
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
    bg: 'none',
    gap: 'none',
  },
})

export type TemplateVariants = VariantProps<typeof templateVariants>

import { cva, type VariantProps } from 'class-variance-authority'

export const sectionVariants = cva('w-full', {
  variants: {
    spacing: {
      none: '',
      sm: 'py-4',
      md: 'py-8',
      lg: 'py-12',
      xl: 'py-16',
    },
    divider: {
      none: '',
      top: 'border-t border-border',
      bottom: 'border-b border-border',
      both: 'border-y border-border',
    },
    bg: {
      none: '',
      muted: 'bg-muted',
      white: 'bg-white',
      dark: 'bg-gray-900 text-white',
    },
  },
  defaultVariants: {
    spacing: 'md',
    divider: 'none',
    bg: 'none',
  },
})

export type SectionVariants = VariantProps<typeof sectionVariants>

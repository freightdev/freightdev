import { cva, type VariantProps } from 'class-variance-authority'

export const bodyVariants = cva('w-full h-full', {
  variants: {
    bg: {
      white: 'bg-white text-black',
      dark: 'bg-gray-900 text-white',
      muted: 'bg-muted text-muted-foreground',
    },
    font: {
      sans: 'font-sans',
      serif: 'font-serif',
      mono: 'font-mono',
    },
    spacing: {
      normal: '',
      loose: 'leading-loose',
      tight: 'leading-tight',
    },
  },
  defaultVariants: {
    bg: 'white',
    font: 'sans',
    spacing: 'normal',
  },
})

export type BodyVariants = VariantProps<typeof bodyVariants>

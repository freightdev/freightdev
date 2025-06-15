import { cva, type VariantProps } from 'class-variance-authority'

export const tooltipVariants = cva(
  'absolute z-50 inline-block rounded bg-black px-2 py-1 text-xs text-white shadow-sm',
  {
    variants: {
      position: {
        top: 'bottom-full mb-1',
        bottom: 'top-full mt-1',
        left: 'right-full mr-1',
        right: 'left-full ml-1',
      },
    },
    defaultVariants: {
      position: 'top',
    },
  }
)

export type TooltipVariants = VariantProps<typeof tooltipVariants>

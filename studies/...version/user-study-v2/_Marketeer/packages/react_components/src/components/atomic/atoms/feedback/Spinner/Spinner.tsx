'use client'

import { cn } from '@ui/shared/utils'

export const Spinner = ({ className }: { className?: string }) => {
  return (
    <svg
      className={cn('h-5 w-5 animate-spin text-muted-foreground', className)}
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="4"
      />
      <path
        className="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8v4l3.5-3.5L12 0v4a8 8 0 000 16v4l3.5-3.5L12 20v-4a8 8 0 01-8-8z"
      />
    </svg>
  )
}

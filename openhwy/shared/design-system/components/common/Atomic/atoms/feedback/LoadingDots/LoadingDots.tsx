'use client'

import { cn } from '@ui/shared/utils'

export const LoadingDots = ({ className }: { className?: string }) => {
  return (
    <span className={cn('inline-flex gap-1', className)}>
      <span className="h-2 w-2 animate-bounce rounded-full bg-current [animation-delay:-0.3s]" />
      <span className="h-2 w-2 animate-bounce rounded-full bg-current [animation-delay:-0.15s]" />
      <span className="w-2 h-2 bg-current rounded-full animate-bounce" />
    </span>
  )
}

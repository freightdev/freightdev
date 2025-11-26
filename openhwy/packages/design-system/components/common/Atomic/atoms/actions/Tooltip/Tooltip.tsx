'use client'

import * as TooltipPrimitive from '@radix-ui/react-tooltip'
import { cn } from '@ui/shared/utils'

export const TooltipProvider = TooltipPrimitive.Provider

export function Tooltip({
  children,
  content,
  className,
  ...props
}: TooltipPrimitive.TooltipContentProps & {
  children: React.ReactNode
  content: string
}) {
  return (
    <TooltipPrimitive.Root delayDuration={200}>
      <TooltipPrimitive.Trigger asChild>
        {children}
      </TooltipPrimitive.Trigger>
      <TooltipPrimitive.Portal>
        <TooltipPrimitive.Content
          side="top"
          align="center"
          className={cn(
            'z-50 overflow-hidden rounded-md bg-muted px-3 py-1.5 text-sm text-muted-foreground shadow-md animate-in fade-in-0 zoom-in-95',
            className
          )}
          {...props}
        >
          {content}
        </TooltipPrimitive.Content>
      </TooltipPrimitive.Portal>
    </TooltipPrimitive.Root>
  )
}

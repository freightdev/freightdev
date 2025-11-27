'use client'

import * as TogglePrimitive from '@radix-ui/react-toggle'
import { cn } from '@ui/shared/utils'

export function Toggle({
  className,
  ...props
}: React.ComponentPropsWithoutRef<typeof TogglePrimitive.Root>) {
  return (
    <TogglePrimitive.Root
      className={cn(
        'inline-flex items-center justify-center rounded-md border border-input bg-background px-3 py-1.5 text-sm font-medium ring-offset-background transition hover:bg-accent hover:text-accent-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 data-[state=on]:bg-muted data-[state=on]:text-foreground',
        className
      )}
      {...props}
    />
  )
}

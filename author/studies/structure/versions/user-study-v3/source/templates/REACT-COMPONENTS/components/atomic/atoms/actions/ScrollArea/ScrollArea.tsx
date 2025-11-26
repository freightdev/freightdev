'use client'

import * as Scroll from '@radix-ui/react-scroll-area'
import { cn } from '@ui/shared/utils'

export function ScrollArea({
  className,
  children,
  ...props
}: React.ComponentPropsWithoutRef<typeof Scroll.Root>) {
  return (
    <Scroll.Root className={cn('overflow-hidden', className)} {...props}>
      <Scroll.Viewport className="h-full w-full rounded-[inherit]">
        {children}
      </Scroll.Viewport>
      <Scroll.Scrollbar
        orientation="vertical"
        className="flex touch-none select-none p-0.5 transition-colors"
      >
        <Scroll.Thumb className="relative flex-1 rounded-full bg-border" />
      </Scroll.Scrollbar>
    </Scroll.Root>
  )
}

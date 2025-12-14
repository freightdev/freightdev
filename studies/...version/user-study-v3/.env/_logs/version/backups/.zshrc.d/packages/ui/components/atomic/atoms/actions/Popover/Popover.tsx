'use client'

import * as RadixPopover from '@radix-ui/react-popover'
import { cn } from '@ui/shared/utils'
import { forwardRef } from 'react'

export const Popover = RadixPopover.Root
export const PopoverTrigger = RadixPopover.Trigger
export const PopoverAnchor = RadixPopover.Anchor

export const PopoverContent = forwardRef<
  React.ElementRef<typeof RadixPopover.Content>,
  React.ComponentPropsWithoutRef<typeof RadixPopover.Content>
>(({ className, align = 'center', sideOffset = 4, ...props }, ref) => (
  <RadixPopover.Portal>
    <RadixPopover.Content
      ref={ref}
      align={align}
      sideOffset={sideOffset}
      className={cn(
        'z-50 w-72 rounded-xl border bg-background p-4 text-popover-foreground shadow-md outline-none animate-in fade-in zoom-in-95',
        className
      )}
      {...props}
    />
  </RadixPopover.Portal>
))

PopoverContent.displayName = 'PopoverContent'

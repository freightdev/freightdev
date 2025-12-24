'use client'

import * as SliderPrimitive from '@radix-ui/react-slider'
import { cn } from '@ui/shared/utils'

export function Slider({
  className,
  ...props
}: React.ComponentPropsWithoutRef<typeof SliderPrimitive.Root>) {
  return (
    <SliderPrimitive.Root
      className={cn(
        'relative flex w-full touch-none select-none items-center',
        className
      )}
      {...props}
    >
      <SliderPrimitive.Track className="relative w-full h-2 overflow-hidden rounded-full grow bg-muted">
        <SliderPrimitive.Range className="absolute h-full bg-primary" />
      </SliderPrimitive.Track>
      <SliderPrimitive.Thumb className="block w-4 h-4 transition rounded-full bg-primary ring-offset-background focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2" />
    </SliderPrimitive.Root>
  )
}

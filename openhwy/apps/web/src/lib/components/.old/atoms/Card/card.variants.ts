import type { Variant } from '@/utils';
import { cn } from '@utils';

const cardVariants: Record<Variant, string> = {
  default: cn(
    'bg-background-card',
    'border border-background-elevated',
    'rounded-xl',
    'transition-all duration-200'
  ),
  primary: cn(
    'bg-background-card',
    'border-2 border-purple-primary',
    'rounded-xl',
    'shadow-lg shadow-purple-primary/20',
    'transition-all duration-200'
  ),
  secondary: cn(
    'bg-background-elevated',
    'border border-background-card',
    'rounded-xl',
    'transition-all duration-200'
  ),
  elevated: cn(
    'bg-background-elevated',
    'border border-background-card',
    'rounded-xl',
    'shadow-xl',
    'transition-all duration-200'
  ),
  outlined: cn(
    'bg-transparent',
    'border-2 border-background-elevated',
    'rounded-xl',
    'transition-all duration-200'
  ),
  ghost: cn('bg-transparent', 'border-0', 'rounded-xl', 'transition-all duration-200'),
  highlighted: cn(
    'bg-background-card',
    'border-2 border-purple-primary',
    'rounded-2xl',
    'shadow-2xl shadow-purple-primary/20',
    'scale-105',
    'transition-all duration-200',
    'relative'
  ),
};

const cardHoverVariants: Record<Variant, string> = {
  default: 'hover:border-purple-primary/50 hover:shadow-lg',
  primary: 'hover:shadow-xl hover:shadow-purple-primary/30 hover:scale-105',
  secondary: 'hover:bg-background-card hover:border-purple-primary/30',
  elevated: 'hover:shadow-2xl hover:border-purple-primary/30',
  outlined: 'hover:border-purple-primary hover:bg-background-card/50',
  ghost: 'hover:bg-background-card/50',
  highlighted: 'hover:shadow-2xl hover:shadow-purple-primary/40',
};

export function getCardClasses(
  variant: Variant = 'default',
  hoverable: boolean = true,
  animated: boolean = false
): string {
  return cn(
    cardVariants[variant],
    hoverable && cardHoverVariants[variant],
    animated && 'animate-fade-in'
  );
}

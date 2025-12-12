import type { Size, Variant } from '@/utils';
import { cn } from '@utils';

export const buttonVariants: Record<Variant, string> = {
  default: cn(
    'bg-background-elevated',
    'text-white',
    'border border-background-elevated',
    'hover:bg-background-card',
    'transition-all duration-200'
  ),
  primary: cn(
    'bg-gradient-purple',
    'text-white',
    'shadow-lg shadow-purple-primary/50',
    'hover:opacity-90',
    'hover:shadow-xl hover:shadow-purple-primary/60',
    'transition-all duration-200'
  ),
  secondary: cn(
    'bg-purple-secondary',
    'text-white',
    'hover:bg-purple-primary',
    'transition-all duration-200'
  ),
  elevated: cn(
    'bg-background-elevated',
    'text-white',
    'shadow-lg',
    'hover:bg-background-card',
    'hover:shadow-xl',
    'transition-all duration-200'
  ),
  outlined: cn(
    'bg-transparent',
    'text-white',
    'border-2 border-purple-primary',
    'hover:bg-purple-primary/10',
    'hover:border-purple-secondary',
    'transition-all duration-200'
  ),
  ghost: cn(
    'bg-transparent',
    'text-text-secondary',
    'hover:text-white',
    'hover:bg-background-card',
    'transition-all duration-200'
  ),
  highlighted: cn(
    'bg-gradient-purple',
    'text-white',
    'shadow-xl shadow-purple-primary/60',
    'hover:opacity-95',
    'hover:shadow-2xl hover:shadow-purple-primary/70',
    'scale-105',
    'transition-all duration-200'
  ),
};

export const buttonSizes: Record<Size, string> = {
  xs: 'px-3 py-1.5 text-xs rounded-md',
  sm: 'px-4 py-2 text-sm rounded-lg',
  md: 'px-6 py-3 text-base rounded-lg',
  lg: 'px-8 py-4 text-lg rounded-xl',
  xl: 'px-10 py-5 text-xl rounded-xl',
  '2xl': 'px-12 py-6 text-2xl rounded-2xl',
};

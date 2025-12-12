import type { Alignment } from '@/utils';
import { cn } from '@utils';
import type { HeroProps } from './hero.types';

const HERO_BACKGROUNDS = {
  default: 'bg-background',
  card: 'bg-background-card',
  elevated: 'bg-background-elevated',
  gradient: 'bg-gradient-to-b from-purple-dark/20 to-background',
};

const HERO_SPACING = {
  none: 'py-0',
  xs: 'py-12',
  sm: 'py-16',
  md: 'py-20',
  lg: 'py-24',
  xl: 'py-32',
  '2xl': 'py-40',
};

const HERO_ALIGNMENT: Record<Alignment, string> = {
  left: 'text-left items-start',
  center: 'text-center items-center',
  right: 'text-right items-end',
};

export function getHeroWrapperClasses(props: HeroProps): string {
  return cn(
    HERO_BACKGROUNDS[props.background ?? 'default'],
    HERO_SPACING[props.spacing ?? 'xl'],
    props.className
  );
}

export function getHeroLayoutClasses(alignment: Alignment = 'center'): string {
  return cn('flex flex-col gap-6', HERO_ALIGNMENT[alignment]);
}

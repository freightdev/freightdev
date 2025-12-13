import type { Alignment, BaseComponentProps } from '@/utils';

export interface HeroCta {
  label: string;
  href: string;
  variant?: 'primary' | 'outlined' | 'ghost';
}

export interface HeroProps extends BaseComponentProps {
  title: string;
  subtitle?: string;
  description?: string;
  image?: string;
  video?: string;
  alignment?: Alignment;
  background?: 'default' | 'card' | 'elevated' | 'gradient';
  spacing?: 'none' | 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl';
  primaryCta?: HeroCta;
  secondaryCta?: HeroCta;
}

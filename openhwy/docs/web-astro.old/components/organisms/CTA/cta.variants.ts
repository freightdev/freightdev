import { cn } from '@utils';
import type { CTAProps } from './cta.configs';

const CTA_BACKGROUND = {
  default: 'bg-background-card',
  gradient: 'bg-gradient-to-b from-purple-dark/30 via-background to-purple-dark/30',
  minimal: 'bg-transparent',
};

const CTA_SPACING = {
  none: 'py-0',
  xs: 'py-12',
  sm: 'py-16',
  md: 'py-20',
  lg: 'py-24',
  xl: 'py-32',
  '2xl': 'py-40',
};

export function getCtaWrapperClasses(props: CTAProps): string {
  return cn(
    CTA_BACKGROUND[props.variant ?? 'gradient'],
    CTA_SPACING[props.spacing ?? 'xl'],
    props.className
  );
}

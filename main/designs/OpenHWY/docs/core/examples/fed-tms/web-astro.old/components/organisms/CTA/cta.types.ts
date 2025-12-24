import type { BaseComponentProps } from '@/utils';

export interface CtaButton {
  label: string;
  href: string;
  variant?: 'primary' | 'outlined' | 'ghost';
}

export interface CTAProps extends BaseComponentProps {
  title: string;
  description?: string;
  primaryButton: CtaButton;
  secondaryButton?: CtaButton;
  variant?: 'default' | 'gradient' | 'minimal';
  spacing?: 'none' | 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl';
  background?: 'default' | 'card' | 'elevated' | 'gradient';
}

import type { Alignment, BaseComponentProps, Size } from '@/utils';

export type SectionSpacing = 'none' | 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl';
export type SectionBackground =
  | 'default'
  | 'card'
  | 'elevated'
  | 'gradient'
  | 'gradientPurple';

export interface SectionHeadingProps {
  title?: string;
  subtitle?: string;
  description?: string;
  align?: Alignment;
  maxWidth?: 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl';
  padded?: boolean;
}

export interface SectionProps extends BaseComponentProps {
  heading?: SectionHeadingProps;
  spacing?: SectionSpacing;
  background?: SectionBackground;
  container?: boolean;
  maxWidth?: Size;
  accentBorder?: boolean;
  fullWidth?: boolean;
}

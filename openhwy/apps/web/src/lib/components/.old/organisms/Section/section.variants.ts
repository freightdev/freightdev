import { cn } from '@utils';
import type { SectionHeadingProps, SectionProps, SectionSpacing } from './section.types';

const SECTION_BACKGROUNDS: Record<Required<SectionProps>['background'], string> = {
  default: 'bg-background',
  card: 'bg-background-card',
  elevated: 'bg-background-elevated',
  gradient: 'bg-gradient-to-b from-background to-background-card',
  gradientPurple: 'bg-gradient-to-b from-purple-dark/20 to-background',
};

const SECTION_SPACING: Record<SectionSpacing, string> = {
  none: 'py-0',
  xs: 'py-8',
  sm: 'py-12',
  md: 'py-16',
  lg: 'py-20',
  xl: 'py-24',
  '2xl': 'py-32',
};

const HEADING_ALIGNMENT: Record<string, string> = {
  left: 'text-left',
  center: 'text-center',
  right: 'text-right',
};

const HEADING_WIDTH: Record<string, string> = {
  xs: 'max-w-2xl',
  sm: 'max-w-3xl',
  md: 'max-w-4xl',
  lg: 'max-w-5xl',
  xl: 'max-w-6xl',
  '2xl': 'max-w-7xl',
};

export function getSectionWrapperClasses(props: SectionProps): string {
  return cn(
    SECTION_BACKGROUNDS[props.background ?? 'default'],
    SECTION_SPACING[props.spacing ?? 'lg'],
    props.accentBorder && 'border-t border-purple-primary/20',
    props.className
  );
}

export function getHeadingClasses(heading: SectionHeadingProps): string {
  return cn(
    'mb-12',
    HEADING_ALIGNMENT[heading.align ?? 'center'],
    heading.align === 'center' && 'mx-auto',
    HEADING_WIDTH[heading.maxWidth ?? 'lg'],
    heading.padded && 'px-4 sm:px-6 lg:px-8'
  );
}

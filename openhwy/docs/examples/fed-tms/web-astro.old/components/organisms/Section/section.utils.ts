import type { SectionHeadingProps, SectionProps } from './section.types';
import { getSectionWrapperClasses } from './section.variants';

export function buildSectionClasses(props: SectionProps): string {
  return getSectionWrapperClasses(props);
}

export function resolveHeadingConfig(props: SectionProps): SectionHeadingProps | null {
  const heading = props.heading;
  if (!heading) return null;

  const hasContent = heading.title || heading.subtitle || heading.description;
  if (!hasContent) return null;

  return {
    align: heading.align ?? 'center',
    maxWidth: heading.maxWidth ?? 'lg',
    padded: heading.padded ?? props.container === false,
    title: heading.title,
    subtitle: heading.subtitle,
    description: heading.description,
  };
}

import { cn, getGapClasses, getLayoutClasses } from '@utils';
import type { CardCollectionProps, CardData } from './card.types';

export function asArray<T extends CardData>(data: T | T[]): T[] {
  return Array.isArray(data) ? data : [data];
}

export function getCollectionClasses(props: CardCollectionProps): string {
  return cn(
    getLayoutClasses(props.layout ?? 'grid-3'),
    getGapClasses(props.gap ?? 'lg'),
    props.className
  );
}

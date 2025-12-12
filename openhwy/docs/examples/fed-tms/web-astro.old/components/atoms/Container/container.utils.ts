import type { ContainerProps } from './container.types';
import { cn, getContainerClasses } from '@utils';

export function buildContainerClasses(props: ContainerProps): string {
  if (props.padding === false) {
    return cn(props.center !== false && 'mx-auto', props.className);
  }

  return cn(getContainerClasses(props.maxWidth ?? 'xl'), props.className);
}

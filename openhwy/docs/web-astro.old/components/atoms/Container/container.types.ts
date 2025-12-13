import type { BaseComponentProps, Size } from '@/utils';

export interface ContainerProps extends BaseComponentProps {
  as?: keyof HTMLElementTagNameMap;
  maxWidth?: Size;
  center?: boolean;
  padding?: boolean;
}

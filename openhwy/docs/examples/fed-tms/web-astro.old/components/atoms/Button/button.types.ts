import type { BaseComponentProps, Size, Variant } from '@/utils';

export type ButtonTag = 'button' | 'a';

export interface ButtonProps extends BaseComponentProps {
  variant?: Variant;
  size?: Size;
  type?: 'button' | 'submit' | 'reset';
  href?: string;
  external?: boolean;
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
  iconBefore?: any;
  iconAfter?: any;
}

export interface ButtonVisualConfig {
  variant: Variant;
  size: Size;
  fullWidth: boolean;
  disabled: boolean;
  loading: boolean;
  className?: string;
}

export interface ButtonAttributeConfig {
  href?: string;
  external: boolean;
  type: 'button' | 'submit' | 'reset';
  disabled: boolean;
  loading: boolean;
  id?: string;
  dataTestId?: string;
}

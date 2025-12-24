/**
 * Variant to ClassName Mapping
 */

import type { LayoutType, Size } from '@/utils';
import { cn } from './cn';

export function getPaddingClasses(size: Size = 'md'): string {
  const paddingMap: Record<Size, string> = {
    xs: 'p-2',
    sm: 'p-4',
    md: 'p-6',
    lg: 'p-8',
    xl: 'p-12',
    '2xl': 'p-16',
  };
  return paddingMap[size];
}

export function getSpacingClasses(size: Size = 'md'): string {
  const spacingMap: Record<Size, string> = {
    xs: 'space-y-2',
    sm: 'space-y-4',
    md: 'space-y-6',
    lg: 'space-y-8',
    xl: 'space-y-12',
    '2xl': 'space-y-16',
  };
  return spacingMap[size];
}

export function getGapClasses(size: Size = 'md'): string {
  const gapMap: Record<Size, string> = {
    xs: 'gap-2',
    sm: 'gap-4',
    md: 'gap-6',
    lg: 'gap-8',
    xl: 'gap-12',
    '2xl': 'gap-16',
  };
  return gapMap[size];
}

export function getRoundedClasses(size: Size = 'md'): string {
  const roundedMap: Record<Size, string> = {
    xs: 'rounded',
    sm: 'rounded-md',
    md: 'rounded-lg',
    lg: 'rounded-xl',
    xl: 'rounded-2xl',
    '2xl': 'rounded-3xl',
  };
  return roundedMap[size];
}

export function getLayoutClasses(layout: LayoutType = 'grid-3'): string {
  const layoutMap: Record<LayoutType, string> = {
    'grid-1': 'grid grid-cols-1',
    'grid-2': 'grid grid-cols-1 md:grid-cols-2',
    'grid-3': 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3',
    'grid-4': 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4',
    list: 'flex flex-col',
    stack: 'flex flex-col',
    flex: 'flex flex-wrap',
  };
  return layoutMap[layout];
}

export function getShadowClasses(shadow: boolean | Size = false): string {
  if (shadow === false) return '';
  if (shadow === true) return 'shadow-lg';

  const shadowMap: Record<Size, string> = {
    xs: 'shadow-sm',
    sm: 'shadow',
    md: 'shadow-lg',
    lg: 'shadow-xl',
    xl: 'shadow-2xl',
    '2xl': 'shadow-2xl',
  };
  return shadowMap[shadow];
}

export function getContainerClasses(maxWidth: Size = 'xl'): string {
  const widthMap: Record<Size, string> = {
    xs: 'max-w-3xl',
    sm: 'max-w-4xl',
    md: 'max-w-5xl',
    lg: 'max-w-6xl',
    xl: 'max-w-7xl',
    '2xl': 'max-w-screen-2xl',
  };
  return cn(widthMap[maxWidth], 'mx-auto px-4 sm:px-6 lg:px-8');
}

import type * as React from 'react';

type ElementRef<T extends React.ElementType> =
  React.ComponentPropsWithRef<T>['ref'];

export type PolymorphicComponentProps<T extends React.ElementType, P = object> = // ✅ changed {} to object
  P & { as?: T } & Omit<React.ComponentPropsWithoutRef<T>, keyof P | 'as'>;

export type PolymorphicComponentWithRef<T extends React.ElementType, P = object> = // ✅ changed {} to object
  React.ForwardRefExoticComponent<PolymorphicComponentProps<T, P> & { ref?: ElementRef<T> }>;

'use client';

import { cn } from '@ui/shared/utils';
import type { PolymorphicComponentWithRef } from '@ui/shared/utils/types/polymorphic-types';
import * as React from 'react';

type AsProp<T extends React.ElementType> = {
  as?: T;
};

type PolymorphicProps<T extends React.ElementType, Props = {}> =
  React.PropsWithChildren<Props & AsProp<T>> &
  Omit<React.ComponentPropsWithoutRef<T>, keyof Props | 'as'>;

export type ButtonProps<T extends React.ElementType = 'button'> = PolymorphicProps<
  T,
  {
    className?: string;
  }
>;

export const Button = React.forwardRef(
  <T extends React.ElementType = 'button'>(
    { as, className, children, ...props }: ButtonProps<T>,
    ref: React.Ref<any>
  ) => {
    const Component = as || 'button';

    return (
      <Component
        ref={ref}
        className={cn('inline-flex items-center justify-center', className)}
        {...props}
      >
        {children}
      </Component>
    );
  }
) as PolymorphicComponentWithRef<'button', ButtonProps>;

Button.displayName = 'Button';

import type { ButtonAttributeConfig, ButtonVisualConfig } from './button.types';
import { buttonSizes, buttonVariants } from './button.variants';
import { cn } from '@utils';

export function buildButtonClasses(config: ButtonVisualConfig): string {
  return cn(
    buttonVariants[config.variant],
    buttonSizes[config.size],
    'font-semibold inline-flex items-center justify-center transition-all duration-200',
    config.fullWidth && 'w-full',
    (config.disabled || config.loading) && 'cursor-not-allowed',
    config.loading && 'opacity-70 cursor-wait',
    config.className
  );
}

export function buildButtonAttributes(config: ButtonAttributeConfig) {
  if (config.href) {
    return {
      Tag: 'a',
      attributes: {
        href: config.href,
        target: config.external ? '_blank' : undefined,
        rel: config.external ? 'noopener noreferrer' : undefined,
        id: config.id,
        'data-testid': config.dataTestId,
        'aria-busy': config.loading || undefined,
        'aria-disabled': config.disabled || undefined,
      },
    } as const;
  }

  return {
    Tag: 'button',
    attributes: {
      type: config.type,
      disabled: config.disabled,
      id: config.id,
      'data-testid': config.dataTestId,
      'aria-busy': config.loading || undefined,
    },
  } as const;
}

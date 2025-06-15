'use client'

import { cn } from '@ui/utils'
import type { FormFieldProps } from './FormField.props'
import { Text } from '@ui/components/Atoms'

export const FormField = ({
  label,
  htmlFor,
  error,
  description,
  required,
  className,
  children,
}: FormFieldProps) => {
  return (
    <div className={cn('space-y-1.5', className)}>
      {label && (
        <label
          htmlFor={htmlFor}
          className="block text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
        >
          {label}
          {required && <span className="ml-0.5 text-red-500">*</span>}
        </label>
      )}

      {children}

      {description && !error && (
        <Text as="p" size="sm" tone="muted">
          {description}
        </Text>
      )}

      {error && (
        <Text as="p" size="sm" tone="destructive">
          {error}
        </Text>
      )}
    </div>
  )
}

FormField.displayName = 'FormField'

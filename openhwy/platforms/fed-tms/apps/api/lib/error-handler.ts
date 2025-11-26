/**
 * Error Handling Utilities
 * Standardized error handling for all endpoints
 */

import { errorResponse, HTTP_STATUS } from './api-utils'

export class AppError extends Error {
  constructor(
    public message: string,
    public statusCode: number = HTTP_STATUS.INTERNAL_ERROR,
    public code?: string
  ) {
    super(message)
    this.name = 'AppError'
  }
}

export class ValidationError extends AppError {
  constructor(message: string, code?: string) {
    super(message, HTTP_STATUS.BAD_REQUEST, code || 'VALIDATION_ERROR')
  }
}

export class AuthError extends AppError {
  constructor(message: string = 'Unauthorized', code?: string) {
    super(message, HTTP_STATUS.UNAUTHORIZED, code || 'UNAUTHORIZED')
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Forbidden', code?: string) {
    super(message, HTTP_STATUS.FORBIDDEN, code || 'FORBIDDEN')
  }
}

export class NotFoundError extends AppError {
  constructor(message: string = 'Resource not found', code?: string) {
    super(message, HTTP_STATUS.NOT_FOUND, code || 'NOT_FOUND')
  }
}

export class ConflictError extends AppError {
  constructor(message: string = 'Conflict', code?: string) {
    super(message, HTTP_STATUS.CONFLICT, code || 'CONFLICT')
  }
}

/**
 * Handle errors in API routes
 */
export function handleError(error: unknown) {
  console.error('API Error:', error)

  if (error instanceof AppError) {
    return errorResponse(error.message, error.statusCode, error.code)
  }

  if (error instanceof SyntaxError) {
    return errorResponse('Invalid JSON', HTTP_STATUS.BAD_REQUEST, 'INVALID_JSON')
  }

  if (error instanceof Error) {
    // Handle specific error types
    if (error.message.includes('Unique constraint')) {
      return errorResponse('Resource already exists', HTTP_STATUS.CONFLICT, 'DUPLICATE_ENTRY')
    }

    if (error.message.includes('Record to delete does not exist')) {
      return errorResponse('Resource not found', HTTP_STATUS.NOT_FOUND, 'NOT_FOUND')
    }

    return errorResponse(error.message, HTTP_STATUS.INTERNAL_ERROR, 'INTERNAL_ERROR')
  }

  return errorResponse('An unexpected error occurred', HTTP_STATUS.INTERNAL_ERROR)
}

/**
 * Assert condition, throw error if false
 */
export function assertExists<T>(value: T | null | undefined, message: string): T {
  if (!value) {
    throw new NotFoundError(message)
  }
  return value
}

/**
 * Assert user is authenticated
 */
export function assertAuth(user: any, message: string = 'Unauthorized') {
  if (!user) {
    throw new AuthError(message)
  }
}

/**
 * Assert condition with custom error
 */
export function assert(condition: boolean, message: string, statusCode = HTTP_STATUS.BAD_REQUEST) {
  if (!condition) {
    throw new AppError(message, statusCode)
  }
}

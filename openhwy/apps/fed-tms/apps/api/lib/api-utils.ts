/**
 * API Response Utilities
 * Standardized response formatting for all endpoints
 */

import { NextResponse } from 'next/server'

interface SuccessResponse<T> {
  success: true
  data: T
  timestamp: string
}

interface ErrorResponse {
  success: false
  error: string
  code?: string
  timestamp: string
}

interface PaginatedResponse<T> {
  success: true
  data: T[]
  pagination: {
    total: number
    page: number
    limit: number
    totalPages: number
  }
  timestamp: string
}

/**
 * Format successful response
 */
export function successResponse<T>(data: T): NextResponse<SuccessResponse<T>> {
  return NextResponse.json({
    success: true,
    data,
    timestamp: new Date().toISOString(),
  })
}

/**
 * Format paginated response
 */
export function paginatedResponse<T>(
  data: T[],
  total: number,
  page: number,
  limit: number
): NextResponse<PaginatedResponse<T>> {
  return NextResponse.json({
    success: true,
    data,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    },
    timestamp: new Date().toISOString(),
  })
}

/**
 * Format error response
 */
export function errorResponse(
  message: string,
  statusCode: number = 500,
  code?: string
): NextResponse<ErrorResponse> {
  return NextResponse.json(
    {
      success: false,
      error: message,
      code,
      timestamp: new Date().toISOString(),
    },
    { status: statusCode }
  )
}

/**
 * Common HTTP status codes with descriptions
 */
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL_ERROR: 500,
  NOT_IMPLEMENTED: 501,
} as const

/**
 * Extract pagination params from request
 */
export function getPaginationParams(searchParams: URLSearchParams) {
  const page = Math.max(1, parseInt(searchParams.get('page') || '1'))
  const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '10')))

  return { page, limit, skip: (page - 1) * limit }
}

/**
 * Extract sort params from request
 */
export function getSortParams(searchParams: URLSearchParams) {
  const sortBy = searchParams.get('sortBy') || 'created_at'
  const sortOrder = (searchParams.get('sortOrder') || 'desc') as 'asc' | 'desc'

  return { sortBy, sortOrder }
}

/**
 * Extract filter params from request
 */
export function getFilterParams(searchParams: URLSearchParams) {
  const filters: Record<string, string | string[]> = {}

  // Common filters
  const status = searchParams.get('status')
  const companyId = searchParams.get('companyId')
  const userId = searchParams.get('userId')
  const search = searchParams.get('search')
  const startDate = searchParams.get('startDate')
  const endDate = searchParams.get('endDate')

  if (status) filters.status = status
  if (companyId) filters.companyId = companyId
  if (userId) filters.userId = userId
  if (search) filters.search = search
  if (startDate) filters.startDate = startDate
  if (endDate) filters.endDate = endDate

  return filters
}

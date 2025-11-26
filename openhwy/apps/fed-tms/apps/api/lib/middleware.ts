/**
 * API Middleware
 * Authentication, logging, and common middleware functions
 */

import { auth } from '@repo/auth'
import { NextRequest, NextResponse } from 'next/server'
import { AuthError } from './error-handler'

/**
 * Require authentication for a route
 */
export async function requireAuth(request: NextRequest) {
  const user = await auth()

  if (!user) {
    throw new AuthError('Authentication required')
  }

  return user
}

/**
 * Require specific role
 */
export async function requireRole(request: NextRequest, allowedRoles: string[]) {
  const user = await auth()

  if (!user) {
    throw new AuthError('Authentication required')
  }

  // Role check would come from user roles in database
  // This is placeholder - actual implementation depends on your role storage

  return user
}

/**
 * Get authenticated user context
 */
export async function getUserContext(request: NextRequest) {
  const user = await auth()

  if (!user) {
    return null
  }

  return {
    userId: user.userId,
    companyId: user.orgId,
    user: user.user,
  }
}

/**
 * Extract query parameters with validation
 */
export function getQueryParams(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams

  return {
    page: parseInt(searchParams.get('page') || '1'),
    limit: parseInt(searchParams.get('limit') || '10'),
    sortBy: searchParams.get('sortBy') || 'created_at',
    sortOrder: (searchParams.get('sortOrder') || 'desc') as 'asc' | 'desc',
    search: searchParams.get('search'),
    status: searchParams.get('status'),
    companyId: searchParams.get('companyId'),
    startDate: searchParams.get('startDate'),
    endDate: searchParams.get('endDate'),
  }
}

/**
 * Log API request
 */
export function logRequest(request: NextRequest, data?: any) {
  console.log(`[API] ${request.method} ${request.nextUrl.pathname}`, {
    timestamp: new Date().toISOString(),
    params: request.nextUrl.searchParams,
    ...(data && { data }),
  })
}

/**
 * Log API response
 */
export function logResponse(statusCode: number, duration: number, error?: any) {
  console.log(`[API] Response:`, {
    statusCode,
    durationMs: duration,
    ...(error && { error: error.message }),
  })
}

/**
 * Get request body safely
 */
export async function getRequestBody<T = any>(request: NextRequest): Promise<T> {
  try {
    const body = await request.json()
    return body as T
  } catch (error) {
    throw new Error('Invalid JSON in request body')
  }
}

/**
 * CORS headers for API responses
 */
export function withCORS(response: NextResponse) {
  response.headers.set('Access-Control-Allow-Origin', '*')
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS')
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization')
  return response
}

/**
 * Rate limiting key from request
 */
export function getRateLimitKey(request: NextRequest): string {
  const ip = request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown'
  return ip
}

/**
 * Check if request is from authenticated user
 */
export async function isAuthenticated(): boolean {
  const user = await auth()
  return !!user
}

/**
 * Get company context (tenant isolation)
 */
export async function getCompanyContext() {
  const user = await auth()

  if (!user) {
    throw new AuthError('Authentication required')
  }

  return {
    companyId: user.orgId,
    userId: user.userId,
  }
}

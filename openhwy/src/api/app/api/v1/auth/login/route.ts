/**
 * POST /api/v1/auth/login
 * User login endpoint
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError } from '@/lib/error-handler'
import { successResponse, errorResponse, HTTP_STATUS } from '@/lib/api-utils'
import { LoginSchema } from '@/lib/validators'
import { logRequest } from '@/lib/middleware'

export async function POST(request: NextRequest) {
  const startTime = Date.now()

  try {
    logRequest(request)

    // Parse and validate request body
    const body = await request.json()
    const { email, password } = LoginSchema.parse(body)

    // Find user by email
    const user = await database.user.findUnique({
      where: { email },
    })

    if (!user) {
      return errorResponse('Invalid email or password', HTTP_STATUS.UNAUTHORIZED)
    }

    // In production, verify password hash
    // For now, placeholder - your auth-service handles this
    if (!password) {
      return errorResponse('Invalid email or password', HTTP_STATUS.UNAUTHORIZED)
    }

    // Get user roles
    const roles = await database.userCompanyRole.findMany({
      where: { user_id: user.id },
      include: { role: true, company: true },
    })

    if (roles.length === 0) {
      return errorResponse('User has no assigned roles', HTTP_STATUS.FORBIDDEN)
    }

    // Return user with roles (actual JWT token would be issued by auth-service)
    return successResponse({
      user: {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        avatar_url: user.avatar_url,
      },
      roles: roles.map((r) => ({
        company_id: r.company_id,
        company_name: r.company.name,
        role: r.role.name,
        permissions: r.role.permissions,
      })),
      // In production, this would include:
      // accessToken: "...",
      // refreshToken: "...",
      // expiresIn: 3600
    })
  } catch (error) {
    return handleError(error)
  }
}

// Handle other methods
export async function GET() {
  return errorResponse('Method not allowed', HTTP_STATUS.INTERNAL_ERROR)
}

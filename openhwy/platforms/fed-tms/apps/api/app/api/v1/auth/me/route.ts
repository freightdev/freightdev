/**
 * GET /api/v1/auth/me
 * Get current authenticated user
 */

import { NextRequest } from 'next/server'
import { handleError, AuthError } from '@/lib/error-handler'
import { successResponse, HTTP_STATUS } from '@/lib/api-utils'
import { requireAuth } from '@/lib/middleware'
import { database } from '@repo/database'

export async function GET(request: NextRequest) {
  try {
    // Require authentication
    const authUser = await requireAuth(request)

    // Get user details from database
    const user = await database.user.findUnique({
      where: { id: authUser.userId },
      select: {
        id: true,
        email: true,
        first_name: true,
        last_name: true,
        phone: true,
        avatar_url: true,
        status: true,
        created_at: true,
        updated_at: true,
      },
    })

    if (!user) {
      throw new AuthError('User not found')
    }

    // Get user's company roles
    const roles = await database.userCompanyRole.findMany({
      where: { user_id: authUser.userId },
      include: {
        role: {
          select: {
            id: true,
            name: true,
            permissions: true,
          },
        },
        company: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    })

    return successResponse({
      user,
      roles: roles.map((r) => ({
        company_id: r.company.id,
        company_name: r.company.name,
        role_id: r.role.id,
        role_name: r.role.name,
        permissions: r.role.permissions,
      })),
    })
  } catch (error) {
    return handleError(error)
  }
}

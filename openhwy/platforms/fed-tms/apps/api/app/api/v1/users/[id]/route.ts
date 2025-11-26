/**
 * GET /api/v1/users/[id] - Get user by ID
 * PUT /api/v1/users/[id] - Update user
 * DELETE /api/v1/users/[id] - Delete user
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError } from '@/lib/error-handler'
import { successResponse, errorResponse, HTTP_STATUS } from '@/lib/api-utils'
import { UpdateUserSchema } from '@/lib/validators'
import { requireAuth, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - Get user by ID
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const user = await database.user.findUnique({
      where: { id: params.id },
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
      throw new NotFoundError('User not found')
    }

    // Verify user belongs to same company
    const userRole = await database.userCompanyRole.findFirst({
      where: {
        user_id: params.id,
        company_id: companyId,
      },
    })

    if (!userRole) {
      throw new NotFoundError('User not found in your organization')
    }

    return successResponse(user)
  } catch (error) {
    return handleError(error)
  }
}

// PUT - Update user
export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify user belongs to same company
    const userRole = await database.userCompanyRole.findFirst({
      where: {
        user_id: params.id,
        company_id: companyId,
      },
    })

    if (!userRole) {
      throw new NotFoundError('User not found in your organization')
    }

    const body = await request.json()
    const updates = UpdateUserSchema.parse(body)

    const user = await database.user.update({
      where: { id: params.id },
      data: updates,
      select: {
        id: true,
        email: true,
        first_name: true,
        last_name: true,
        phone: true,
        avatar_url: true,
        status: true,
        updated_at: true,
      },
    })

    return successResponse(user)
  } catch (error) {
    return handleError(error)
  }
}

// DELETE - Delete user
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify user belongs to same company
    const userRole = await database.userCompanyRole.findFirst({
      where: {
        user_id: params.id,
        company_id: companyId,
      },
    })

    if (!userRole) {
      throw new NotFoundError('User not found in your organization')
    }

    // Delete user (cascade will handle related records)
    await database.user.delete({
      where: { id: params.id },
    })

    return successResponse({ message: 'User deleted successfully' })
  } catch (error) {
    return handleError(error)
  }
}

/**
 * GET /api/v1/notifications - Get user notifications
 * POST /api/v1/notifications - Create notification
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, ValidationError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { CreateNotificationSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

// GET - Get user notifications
export async function GET(request: NextRequest) {
  try {
    const user = await requireAuth(request)
    const { page, limit, skip } = getQueryParams(request)
    const { companyId } = await getCompanyContext()

    // Get total count
    const total = await database.notification.count({
      where: { user_id: user.userId },
    })

    // Get notifications
    const notifications = await database.notification.findMany({
      where: { user_id: user.userId },
      skip,
      take: limit,
      orderBy: { created_at: 'desc' },
    })

    return paginatedResponse(notifications, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Create notification (admin/system use)
export async function POST(request: NextRequest) {
  try {
    const user = await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const body = await request.json()
    const { user_id, type, title, message, link, data } = CreateNotificationSchema.parse(body)

    // Verify target user exists and belongs to company
    const targetUser = await database.user.findFirst({
      where: {
        id: user_id,
        company_roles: {
          some: {
            company_id: companyId,
          },
        },
      },
    })

    if (!targetUser) {
      throw new ValidationError('Target user not found in company')
    }

    // Create notification
    const notification = await database.notification.create({
      data: {
        user_id,
        type,
        title,
        message,
        link: link || null,
        data: data || null,
        read: false,
      },
    })

    const response = successResponse({
      id: notification.id,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      read: notification.read,
      created_at: notification.created_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

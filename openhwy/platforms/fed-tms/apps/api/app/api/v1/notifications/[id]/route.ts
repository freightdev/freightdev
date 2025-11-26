/**
 * GET /api/v1/notifications/[id] - Get notification by ID
 * PUT /api/v1/notifications/[id] - Update notification (mark as read)
 * DELETE /api/v1/notifications/[id] - Delete notification
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError, ForbiddenError } from '@/lib/error-handler'
import { successResponse } from '@/lib/api-utils'
import { UpdateNotificationSchema } from '@/lib/validators'
import { requireAuth } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - Get notification by ID
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const user = await requireAuth(request)

    const notification = await database.notification.findFirst({
      where: {
        id: params.id,
        user_id: user.userId,
      },
    })

    if (!notification) {
      throw new NotFoundError('Notification not found')
    }

    return successResponse(notification)
  } catch (error) {
    return handleError(error)
  }
}

// PUT - Update notification (mark as read)
export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    const user = await requireAuth(request)

    // Verify notification exists and belongs to user
    const notification = await database.notification.findFirst({
      where: {
        id: params.id,
        user_id: user.userId,
      },
    })

    if (!notification) {
      throw new NotFoundError('Notification not found')
    }

    const body = await request.json()
    const updates = UpdateNotificationSchema.parse(body)

    const updated = await database.notification.update({
      where: { id: params.id },
      data: updates,
    })

    return successResponse(updated)
  } catch (error) {
    return handleError(error)
  }
}

// DELETE - Delete notification
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    const user = await requireAuth(request)

    // Verify notification exists
    const notification = await database.notification.findFirst({
      where: {
        id: params.id,
        user_id: user.userId,
      },
    })

    if (!notification) {
      throw new NotFoundError('Notification not found')
    }

    // Delete notification
    await database.notification.delete({
      where: { id: params.id },
    })

    return successResponse({ message: 'Notification deleted successfully' })
  } catch (error) {
    return handleError(error)
  }
}

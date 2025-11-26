/**
 * GET /api/v1/conversations/[id] - Get conversation by ID
 * PUT /api/v1/conversations/[id] - Update conversation
 * DELETE /api/v1/conversations/[id] - Delete conversation
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError, ForbiddenError } from '@/lib/error-handler'
import { successResponse } from '@/lib/api-utils'
import { requireAuth, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

interface UpdateConversationBody {
  name?: string
}

// GET - Get conversation by ID
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const user = await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Get conversation with participant check
    const conversation = await database.conversation.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
      include: {
        participants: {
          select: {
            user_id: true,
            user: {
              select: {
                id: true,
                email: true,
                first_name: true,
                last_name: true,
              },
            },
          },
        },
        messages: {
          select: {
            id: true,
            content: true,
            sender_id: true,
            created_at: true,
          },
          orderBy: { created_at: 'desc' },
          take: 50,
        },
      },
    })

    if (!conversation) {
      throw new NotFoundError('Conversation not found')
    }

    // Verify user is a participant
    const isParticipant = conversation.participants.some((p) => p.user_id === user.userId)
    if (!isParticipant) {
      throw new ForbiddenError('You are not a participant of this conversation')
    }

    return successResponse(conversation)
  } catch (error) {
    return handleError(error)
  }
}

// PUT - Update conversation
export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    const user = await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify conversation exists
    const conversation = await database.conversation.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
      include: {
        participants: {
          select: { user_id: true },
        },
      },
    })

    if (!conversation) {
      throw new NotFoundError('Conversation not found')
    }

    // Verify user is a participant
    const isParticipant = conversation.participants.some((p) => p.user_id === user.userId)
    if (!isParticipant) {
      throw new ForbiddenError('You are not a participant of this conversation')
    }

    const body: UpdateConversationBody = await request.json()

    // Update conversation
    const updated = await database.conversation.update({
      where: { id: params.id },
      data: {
        ...(body.name && { name: body.name }),
        updated_at: new Date(),
      },
      include: {
        participants: {
          select: {
            user_id: true,
            user: {
              select: {
                id: true,
                email: true,
                first_name: true,
                last_name: true,
              },
            },
          },
        },
      },
    })

    return successResponse(updated)
  } catch (error) {
    return handleError(error)
  }
}

// DELETE - Delete conversation
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    const user = await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify conversation exists
    const conversation = await database.conversation.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
      include: {
        participants: {
          select: { user_id: true },
        },
      },
    })

    if (!conversation) {
      throw new NotFoundError('Conversation not found')
    }

    // Verify user is a participant
    const isParticipant = conversation.participants.some((p) => p.user_id === user.userId)
    if (!isParticipant) {
      throw new ForbiddenError('You are not a participant of this conversation')
    }

    // Delete conversation and all related data
    await database.conversation.delete({
      where: { id: params.id },
    })

    return successResponse({ message: 'Conversation deleted successfully' })
  } catch (error) {
    return handleError(error)
  }
}

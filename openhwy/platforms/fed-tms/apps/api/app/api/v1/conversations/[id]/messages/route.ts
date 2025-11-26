/**
 * GET /api/v1/conversations/[id]/messages - List messages
 * POST /api/v1/conversations/[id]/messages - Send message
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { SendMessageSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - List messages in conversation
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    const authUser = await requireAuth(request)
    const { companyId } = await getCompanyContext()
    const { page, limit, skip } = getQueryParams(request)

    // Verify conversation exists and user is participant
    const conversation = await database.conversation.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
        participants: {
          some: {
            user_id: authUser.userId,
          },
        },
      },
    })

    if (!conversation) {
      throw new NotFoundError('Conversation not found or access denied')
    }

    // Get total messages
    const total = await database.message.count({
      where: { conversation_id: params.id },
    })

    // Get messages
    const messages = await database.message.findMany({
      where: { conversation_id: params.id },
      include: {
        sender: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            avatar_url: true,
          },
        },
      },
      skip,
      take: limit,
      orderBy: { created_at: 'asc' },
    })

    return paginatedResponse(messages, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Send message
export async function POST(request: NextRequest, { params }: RouteParams) {
  try {
    const authUser = await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify conversation exists and user is participant
    const conversation = await database.conversation.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
        participants: {
          some: {
            user_id: authUser.userId,
          },
        },
      },
    })

    if (!conversation) {
      throw new NotFoundError('Conversation not found or access denied')
    }

    const body = await request.json()
    const { content, recipient_id, message_type, attachment_url } = SendMessageSchema.parse(body)

    // Create message
    const message = await database.message.create({
      data: {
        conversation_id: params.id,
        sender_id: authUser.userId,
        recipient_id: recipient_id || null,
        content,
        message_type,
        attachment_url: attachment_url || null,
      },
      include: {
        sender: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            avatar_url: true,
          },
        },
      },
    })

    // Update conversation timestamp
    await database.conversation.update({
      where: { id: params.id },
      data: { updated_at: new Date() },
    })

    const response = successResponse({
      id: message.id,
      content: message.content,
      sender: message.sender,
      message_type: message.message_type,
      attachment_url: message.attachment_url,
      created_at: message.created_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

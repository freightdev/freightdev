/**
 * GET /api/v1/conversations - List conversations
 * POST /api/v1/conversations - Create conversation
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, ValidationError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { CreateConversationSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

// GET - List conversations
export async function GET(request: NextRequest) {
  try {
    const authUser = await requireAuth(request)
    const { companyId } = await getCompanyContext()
    const { page, limit, skip, search } = getQueryParams(request)

    // Build where clause - user must be participant
    const where: any = {
      company_id: companyId,
      participants: {
        some: {
          user_id: authUser.userId,
        },
      },
    }

    if (search) {
      where.name = { contains: search, mode: 'insensitive' }
    }

    // Get total count
    const total = await database.conversation.count({ where })

    // Get conversations
    const conversations = await database.conversation.findMany({
      where,
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                first_name: true,
                last_name: true,
                avatar_url: true,
              },
            },
          },
        },
        messages: {
          orderBy: { created_at: 'desc' },
          take: 1,
        },
      },
      skip,
      take: limit,
      orderBy: { updated_at: 'desc' },
    })

    return paginatedResponse(conversations, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Create conversation
export async function POST(request: NextRequest) {
  try {
    const authUser = await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const body = await request.json()
    const { name, is_group, participant_ids } = CreateConversationSchema.parse(body)

    // Ensure current user is included
    const allParticipants = participant_ids ? [...new Set([authUser.userId, ...participant_ids])] : [authUser.userId]

    // Verify all participants exist
    const users = await database.user.findMany({
      where: {
        id: { in: allParticipants },
      },
    })

    if (users.length !== allParticipants.length) {
      throw new ValidationError('One or more participants not found')
    }

    // Create conversation
    const conversation = await database.conversation.create({
      data: {
        company_id: companyId,
        name: name || null,
        is_group: is_group || false,
        participants: {
          createMany: {
            data: allParticipants.map((userId) => ({
              user_id: userId,
            })),
          },
        },
      },
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                first_name: true,
                last_name: true,
                avatar_url: true,
              },
            },
          },
        },
      },
    })

    const response = successResponse({
      id: conversation.id,
      name: conversation.name,
      is_group: conversation.is_group,
      participants: conversation.participants,
      created_at: conversation.created_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

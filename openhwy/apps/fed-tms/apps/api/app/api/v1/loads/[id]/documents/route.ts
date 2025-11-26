/**
 * GET /api/v1/loads/[id]/documents - Get load documents
 * POST /api/v1/loads/[id]/documents - Upload load document
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - Get load documents
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()
    const { page, limit, skip } = getQueryParams(request)

    // Verify load exists
    const load = await database.load.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
    })

    if (!load) {
      throw new NotFoundError('Load not found')
    }

    // Get total documents
    const total = await database.loadDocument.count({
      where: { load_id: params.id },
    })

    // Get documents
    const documents = await database.loadDocument.findMany({
      where: { load_id: params.id },
      skip,
      take: limit,
      orderBy: { uploaded_at: 'desc' },
    })

    return paginatedResponse(documents, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Upload load document
export async function POST(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify load exists
    const load = await database.load.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
    })

    if (!load) {
      throw new NotFoundError('Load not found')
    }

    const body = await request.json()
    const { type, url } = body

    if (!type || !url) {
      return handleError(new Error('Type and URL are required'))
    }

    // Create document
    const document = await database.loadDocument.create({
      data: {
        load_id: params.id,
        type,
        url,
      },
    })

    const response = successResponse({
      id: document.id,
      type: document.type,
      url: document.url,
      uploaded_at: document.uploaded_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

/**
 * GET /api/v1/drivers/[id]/documents - List driver documents
 * POST /api/v1/drivers/[id]/documents - Upload driver document
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError, ValidationError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { CreateDriverDocumentSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - List driver documents
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()
    const { page, limit, skip } = getQueryParams(request)

    // Verify driver exists
    const driver = await database.driver.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
    })

    if (!driver) {
      throw new NotFoundError('Driver not found')
    }

    // Get total documents
    const total = await database.driverDocument.count({
      where: { driver_id: params.id },
    })

    // Get documents
    const documents = await database.driverDocument.findMany({
      where: { driver_id: params.id },
      skip,
      take: limit,
      orderBy: { uploaded_at: 'desc' },
    })

    return paginatedResponse(documents, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Upload driver document
export async function POST(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify driver exists
    const driver = await database.driver.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
    })

    if (!driver) {
      throw new NotFoundError('Driver not found')
    }

    const body = await request.json()
    const { type, document_url, expiry_date } = CreateDriverDocumentSchema.parse(body)

    // Create document
    const document = await database.driverDocument.create({
      data: {
        driver_id: params.id,
        type,
        document_url,
        expiry_date: expiry_date ? new Date(expiry_date) : null,
        status: 'pending',
      },
    })

    const response = successResponse({
      id: document.id,
      type: document.type,
      document_url: document.document_url,
      expiry_date: document.expiry_date,
      status: document.status,
      uploaded_at: document.uploaded_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

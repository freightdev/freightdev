/**
 * GET /api/v1/drivers/[id]/documents/[docId] - Get document
 * PUT /api/v1/drivers/[id]/documents/[docId] - Update document status
 * DELETE /api/v1/drivers/[id]/documents/[docId] - Delete document
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError } from '@/lib/error-handler'
import { successResponse } from '@/lib/api-utils'
import { requireAuth, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string; docId: string }
}

// GET - Get specific document
export async function GET(request: NextRequest, { params }: RouteParams) {
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

    // Get document
    const document = await database.driverDocument.findFirst({
      where: {
        id: params.docId,
        driver_id: params.id,
      },
    })

    if (!document) {
      throw new NotFoundError('Document not found')
    }

    return successResponse(document)
  } catch (error) {
    return handleError(error)
  }
}

// PUT - Update document status
export async function PUT(request: NextRequest, { params }: RouteParams) {
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

    // Get document
    const document = await database.driverDocument.findFirst({
      where: {
        id: params.docId,
        driver_id: params.id,
      },
    })

    if (!document) {
      throw new NotFoundError('Document not found')
    }

    const body = await request.json()
    const { status } = body

    const updated = await database.driverDocument.update({
      where: { id: params.docId },
      data: {
        status: status || document.status,
      },
    })

    return successResponse(updated)
  } catch (error) {
    return handleError(error)
  }
}

// DELETE - Delete document
export async function DELETE(request: NextRequest, { params }: RouteParams) {
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

    // Get document
    const document = await database.driverDocument.findFirst({
      where: {
        id: params.docId,
        driver_id: params.id,
      },
    })

    if (!document) {
      throw new NotFoundError('Document not found')
    }

    // Delete document
    await database.driverDocument.delete({
      where: { id: params.docId },
    })

    return successResponse({ message: 'Document deleted successfully' })
  } catch (error) {
    return handleError(error)
  }
}

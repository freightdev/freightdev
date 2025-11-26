/**
 * GET /api/v1/drivers/[id] - Get driver by ID
 * PUT /api/v1/drivers/[id] - Update driver
 * DELETE /api/v1/drivers/[id] - Delete driver
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError } from '@/lib/error-handler'
import { successResponse } from '@/lib/api-utils'
import { UpdateDriverSchema } from '@/lib/validators'
import { requireAuth, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - Get driver by ID
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const driver = await database.driver.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            first_name: true,
            last_name: true,
            phone: true,
            avatar_url: true,
          },
        },
        documents: true,
        locations: {
          orderBy: { timestamp: 'desc' },
          take: 1,
        },
        ratings: {
          orderBy: { created_at: 'desc' },
          take: 5,
        },
      },
    })

    if (!driver) {
      throw new NotFoundError('Driver not found')
    }

    return successResponse(driver)
  } catch (error) {
    return handleError(error)
  }
}

// PUT - Update driver
export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify driver exists in company
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
    const updates = UpdateDriverSchema.parse(body)

    // Convert date strings if present
    const data: any = { ...updates }
    if (data.license_expiry) {
      data.license_expiry = new Date(data.license_expiry)
    }

    const updatedDriver = await database.driver.update({
      where: { id: params.id },
      data,
      include: {
        user: {
          select: {
            id: true,
            email: true,
            first_name: true,
            last_name: true,
          },
        },
      },
    })

    return successResponse(updatedDriver)
  } catch (error) {
    return handleError(error)
  }
}

// DELETE - Delete driver
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify driver exists in company
    const driver = await database.driver.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
    })

    if (!driver) {
      throw new NotFoundError('Driver not found')
    }

    // Delete driver (cascade will handle related records)
    await database.driver.delete({
      where: { id: params.id },
    })

    return successResponse({ message: 'Driver deleted successfully' })
  } catch (error) {
    return handleError(error)
  }
}

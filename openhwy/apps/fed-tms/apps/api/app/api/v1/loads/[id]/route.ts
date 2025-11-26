/**
 * GET /api/v1/loads/[id] - Get load by ID
 * PUT /api/v1/loads/[id] - Update load
 * DELETE /api/v1/loads/[id] - Delete load
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError } from '@/lib/error-handler'
import { successResponse } from '@/lib/api-utils'
import { UpdateLoadSchema } from '@/lib/validators'
import { requireAuth, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - Get load by ID with assignments and tracking
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const load = await database.load.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
      include: {
        stops: {
          orderBy: { sequence: 'asc' },
        },
        assignments: {
          include: {
            driver: {
              include: {
                user: {
                  select: {
                    id: true,
                    email: true,
                    first_name: true,
                    last_name: true,
                    phone: true,
                  },
                },
              },
            },
          },
        },
        tracking: {
          orderBy: { timestamp: 'desc' },
        },
        documents: true,
        ratings: true,
      },
    })

    if (!load) {
      throw new NotFoundError('Load not found')
    }

    return successResponse(load)
  } catch (error) {
    return handleError(error)
  }
}

// PUT - Update load
export async function PUT(request: NextRequest, { params }: RouteParams) {
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
    const updates = UpdateLoadSchema.parse(body)

    // Convert date strings if present
    const data: any = { ...updates }
    if (data.pickup_date) {
      data.pickup_date = new Date(data.pickup_date)
    }
    if (data.delivery_date) {
      data.delivery_date = new Date(data.delivery_date)
    }

    const updatedLoad = await database.load.update({
      where: { id: params.id },
      data,
      include: {
        assignments: {
          include: {
            driver: true,
          },
        },
      },
    })

    return successResponse(updatedLoad)
  } catch (error) {
    return handleError(error)
  }
}

// DELETE - Delete load
export async function DELETE(request: NextRequest, { params }: RouteParams) {
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

    // Delete load (cascade will handle related records)
    await database.load.delete({
      where: { id: params.id },
    })

    return successResponse({ message: 'Load deleted successfully' })
  } catch (error) {
    return handleError(error)
  }
}

/**
 * GET /api/v1/loads/[id]/tracking - Get load tracking history
 * POST /api/v1/loads/[id]/tracking - Update load tracking
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { UpdateTrackingSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - Get load tracking history
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

    // Get total tracking entries
    const total = await database.loadTracking.count({
      where: { load_id: params.id },
    })

    // Get tracking entries
    const tracking = await database.loadTracking.findMany({
      where: { load_id: params.id },
      skip,
      take: limit,
      orderBy: { timestamp: 'desc' },
    })

    return paginatedResponse(tracking, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Update load tracking
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
    const { status, latitude, longitude, notes } = UpdateTrackingSchema.parse(body)

    // Create tracking entry
    const trackingEntry = await database.loadTracking.create({
      data: {
        load_id: params.id,
        status,
        latitude: latitude || null,
        longitude: longitude || null,
        notes: notes || null,
      },
    })

    // Update load status if final status
    if (status === 'delivered' || status === 'failed') {
      await database.load.update({
        where: { id: params.id },
        data: {
          status: status === 'delivered' ? 'delivered' : 'cancelled',
        },
      })
    } else if (status === 'in_transit') {
      await database.load.update({
        where: { id: params.id },
        data: { status: 'in_transit' },
      })
    }

    const response = successResponse({
      id: trackingEntry.id,
      status: trackingEntry.status,
      latitude: trackingEntry.latitude,
      longitude: trackingEntry.longitude,
      notes: trackingEntry.notes,
      timestamp: trackingEntry.timestamp,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

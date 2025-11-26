/**
 * GET /api/v1/drivers/[id]/locations - Get driver location history
 * POST /api/v1/drivers/[id]/locations - Update driver location
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { UpdateLocationSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - Get driver location history
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

    // Get total locations
    const total = await database.driverLocation.count({
      where: { driver_id: params.id },
    })

    // Get locations
    const locations = await database.driverLocation.findMany({
      where: { driver_id: params.id },
      skip,
      take: limit,
      orderBy: { timestamp: 'desc' },
    })

    return paginatedResponse(locations, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Update driver location
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
    const { latitude, longitude, accuracy } = UpdateLocationSchema.parse(body)

    // Create location entry
    const location = await database.driverLocation.create({
      data: {
        driver_id: params.id,
        latitude,
        longitude,
        accuracy: accuracy || null,
      },
    })

    const response = successResponse({
      id: location.id,
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy: location.accuracy,
      timestamp: location.timestamp,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

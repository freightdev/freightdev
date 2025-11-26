/**
 * GET /api/v1/drivers/[id]/ratings - Get driver ratings
 * POST /api/v1/drivers/[id]/ratings - Add rating
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { CreateRatingSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - Get driver ratings
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

    // Get total ratings
    const total = await database.driverRating.count({
      where: { driver_id: params.id },
    })

    // Get ratings
    const ratings = await database.driverRating.findMany({
      where: { driver_id: params.id },
      skip,
      take: limit,
      orderBy: { created_at: 'desc' },
    })

    // Calculate average rating
    const avgRating = await database.driverRating.aggregate({
      where: { driver_id: params.id },
      _avg: { rating: true },
    })

    return successResponse({
      ratings,
      pagination: {
        total,
        page: Math.ceil(skip / limit) + 1,
        limit,
        totalPages: Math.ceil(total / limit),
      },
      average: avgRating._avg.rating || 0,
      count: total,
    })
  } catch (error) {
    return handleError(error)
  }
}

// POST - Add rating
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
    const { rating, comment, load_id } = CreateRatingSchema.parse(body)

    // Create rating
    const newRating = await database.driverRating.create({
      data: {
        driver_id: params.id,
        rating,
        comment: comment || null,
        load_id: load_id || null,
      },
    })

    // Update driver average rating
    const avgRating = await database.driverRating.aggregate({
      where: { driver_id: params.id },
      _avg: { rating: true },
    })

    // Update driver record
    await database.driver.update({
      where: { id: params.id },
      data: {
        rating: avgRating._avg.rating || 5.0,
      },
    })

    const response = successResponse({
      id: newRating.id,
      rating: newRating.rating,
      comment: newRating.comment,
      created_at: newRating.created_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

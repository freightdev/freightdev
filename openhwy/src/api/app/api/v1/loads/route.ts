/**
 * GET /api/v1/loads - List loads
 * POST /api/v1/loads - Create load
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, ValidationError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { CreateLoadSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

// GET - List loads with pagination
export async function GET(request: NextRequest) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()
    const { page, limit, skip, search, status, startDate, endDate } = getQueryParams(request)

    // Build where clause
    const where: any = { company_id: companyId }

    if (search) {
      where.OR = [
        { reference_number: { contains: search, mode: 'insensitive' } },
        { commodity: { contains: search, mode: 'insensitive' } },
        { pickup_address: { contains: search, mode: 'insensitive' } },
        { delivery_address: { contains: search, mode: 'insensitive' } },
      ]
    }

    if (status) {
      where.status = status
    }

    if (startDate || endDate) {
      where.pickup_date = {}
      if (startDate) where.pickup_date.gte = new Date(startDate)
      if (endDate) where.pickup_date.lte = new Date(endDate)
    }

    // Get total count
    const total = await database.load.count({ where })

    // Get paginated results
    const loads = await database.load.findMany({
      where,
      include: {
        assignments: {
          include: {
            driver: {
              include: {
                user: {
                  select: {
                    first_name: true,
                    last_name: true,
                    email: true,
                  },
                },
              },
            },
          },
        },
      },
      skip,
      take: limit,
      orderBy: { created_at: 'desc' },
    })

    return paginatedResponse(loads, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Create load
export async function POST(request: NextRequest) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const body = await request.json()
    const {
      reference_number,
      pickup_address,
      pickup_city,
      pickup_state,
      pickup_zip,
      pickup_date,
      delivery_address,
      delivery_city,
      delivery_state,
      delivery_zip,
      delivery_date,
      commodity,
      weight,
      dimensions,
      hazmat,
      special_handling,
      rate,
    } = CreateLoadSchema.parse(body)

    // Check if reference number is unique within company
    const existingLoad = await database.load.findFirst({
      where: {
        reference_number,
        company_id: companyId,
      },
    })

    if (existingLoad) {
      throw new ValidationError('Load with this reference number already exists')
    }

    // Create load
    const load = await database.load.create({
      data: {
        company_id: companyId,
        reference_number,
        status: 'pending',
        pickup_address,
        pickup_city,
        pickup_state,
        pickup_zip,
        pickup_date: new Date(pickup_date),
        delivery_address,
        delivery_city,
        delivery_state,
        delivery_zip,
        delivery_date: new Date(delivery_date),
        commodity: commodity || null,
        weight: weight || null,
        dimensions: dimensions || null,
        hazmat,
        special_handling: special_handling || null,
        rate,
        created_by: 'system', // In production: use authenticated user ID
        currency: 'USD',
        payment_status: 'pending',
      },
    })

    const response = successResponse({
      id: load.id,
      reference_number: load.reference_number,
      status: load.status,
      pickup_address: load.pickup_address,
      delivery_address: load.delivery_address,
      pickup_date: load.pickup_date,
      delivery_date: load.delivery_date,
      rate: load.rate,
      created_at: load.created_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

/**
 * GET /api/v1/drivers - List drivers
 * POST /api/v1/drivers - Create driver
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, ValidationError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { CreateDriverSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

// GET - List drivers with pagination
export async function GET(request: NextRequest) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()
    const { page, limit, skip, search, status } = getQueryParams(request)

    // Build where clause
    const where: any = { company_id: companyId }

    if (search) {
      where.user = {
        OR: [
          { email: { contains: search, mode: 'insensitive' } },
          { first_name: { contains: search, mode: 'insensitive' } },
          { last_name: { contains: search, mode: 'insensitive' } },
        ],
      }
    }

    if (status) {
      where.status = status
    }

    // Get total count
    const total = await database.driver.count({ where })

    // Get paginated results
    const drivers = await database.driver.findMany({
      where,
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
      },
      skip,
      take: limit,
      orderBy: { created_at: 'desc' },
    })

    const formattedDrivers = drivers.map((d) => ({
      id: d.id,
      user_id: d.user_id,
      user: d.user,
      license_number: d.license_number,
      license_class: d.license_class,
      license_expiry: d.license_expiry,
      vehicle_type: d.vehicle_type,
      vehicle_vin: d.vehicle_vin,
      vehicle_plate: d.vehicle_plate,
      status: d.status,
      rating: d.rating,
      total_loads: d.total_loads,
      total_miles: d.total_miles,
      created_at: d.created_at,
    }))

    return paginatedResponse(formattedDrivers, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Create driver
export async function POST(request: NextRequest) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const body = await request.json()
    const { user_id, license_number, license_class, license_expiry, vehicle_type, vehicle_vin, vehicle_plate } =
      CreateDriverSchema.parse(body)

    // Verify user exists
    const user = await database.user.findUnique({
      where: { id: user_id },
    })

    if (!user) {
      throw new ValidationError('User not found')
    }

    // Check if driver already exists for this user and company
    const existingDriver = await database.driver.findFirst({
      where: {
        user_id,
        company_id: companyId,
      },
    })

    if (existingDriver) {
      throw new ValidationError('Driver record already exists for this user')
    }

    // Create driver record
    const driver = await database.driver.create({
      data: {
        user_id,
        company_id: companyId,
        license_number,
        license_class: license_class || null,
        license_expiry: license_expiry ? new Date(license_expiry) : null,
        vehicle_type: vehicle_type || null,
        vehicle_vin: vehicle_vin || null,
        vehicle_plate: vehicle_plate || null,
        status: 'active',
      },
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
    })

    const response = successResponse({
      id: driver.id,
      user_id: driver.user_id,
      user: driver.user,
      license_number: driver.license_number,
      license_class: driver.license_class,
      license_expiry: driver.license_expiry,
      vehicle_type: driver.vehicle_type,
      vehicle_vin: driver.vehicle_vin,
      vehicle_plate: driver.vehicle_plate,
      status: driver.status,
      created_at: driver.created_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

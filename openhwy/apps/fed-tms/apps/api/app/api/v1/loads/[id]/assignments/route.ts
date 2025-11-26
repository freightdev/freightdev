/**
 * GET /api/v1/loads/[id]/assignments - List load assignments
 * POST /api/v1/loads/[id]/assignments - Assign driver to load
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError, ValidationError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { AssignLoadSchema } from '@/lib/validators'
import { requireAuth, getCompanyContext, getQueryParams } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - List assignments for a load
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

    // Get total assignments
    const total = await database.loadAssignment.count({
      where: { load_id: params.id },
    })

    // Get assignments
    const assignments = await database.loadAssignment.findMany({
      where: { load_id: params.id },
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
      skip,
      take: limit,
      orderBy: { assigned_at: 'desc' },
    })

    return paginatedResponse(assignments, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Assign driver to load
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
    const { driver_id } = AssignLoadSchema.parse(body)

    // Verify driver exists and belongs to company
    const driver = await database.driver.findFirst({
      where: {
        id: driver_id,
        company_id: companyId,
      },
    })

    if (!driver) {
      throw new ValidationError('Driver not found')
    }

    // Check if driver is already assigned to this load
    const existingAssignment = await database.loadAssignment.findFirst({
      where: {
        load_id: params.id,
        driver_id,
      },
    })

    if (existingAssignment) {
      throw new ValidationError('Driver is already assigned to this load')
    }

    // Create assignment
    const assignment = await database.loadAssignment.create({
      data: {
        load_id: params.id,
        driver_id,
        status: 'pending',
      },
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
    })

    const response = successResponse({
      id: assignment.id,
      load_id: assignment.load_id,
      driver_id: assignment.driver_id,
      driver: assignment.driver,
      status: assignment.status,
      assigned_at: assignment.assigned_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

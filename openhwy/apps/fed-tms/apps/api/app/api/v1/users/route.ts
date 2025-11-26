/**
 * GET /api/v1/users - List users
 * POST /api/v1/users - Create user
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, ValidationError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, errorResponse, HTTP_STATUS } from '@/lib/api-utils'
import { CreateUserSchema } from '@/lib/validators'
import { requireAuth, getQueryParams } from '@/lib/middleware'
import { getCompanyContext } from '@/lib/middleware'

// GET - List users with pagination
export async function GET(request: NextRequest) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()
    const { page, limit, skip, search, status } = getQueryParams(request)

    // Build where clause
    const where: any = {
      company_roles: {
        some: {
          company_id: companyId,
        },
      },
    }

    if (search) {
      where.OR = [
        { email: { contains: search, mode: 'insensitive' } },
        { first_name: { contains: search, mode: 'insensitive' } },
        { last_name: { contains: search, mode: 'insensitive' } },
      ]
    }

    if (status) {
      where.status = status
    }

    // Get total count
    const total = await database.user.count({ where })

    // Get paginated results
    const users = await database.user.findMany({
      where,
      select: {
        id: true,
        email: true,
        first_name: true,
        last_name: true,
        phone: true,
        avatar_url: true,
        status: true,
        created_at: true,
      },
      skip,
      take: limit,
      orderBy: { created_at: 'desc' },
    })

    return paginatedResponse(users, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Create user
export async function POST(request: NextRequest) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const body = await request.json()
    const { email, password, first_name, last_name, phone, role_id } = CreateUserSchema.parse(body)

    // Check if email already exists
    const existingUser = await database.user.findUnique({
      where: { email },
    })

    if (existingUser) {
      throw new ValidationError('Email already in use')
    }

    // Verify role exists
    const role = await database.role.findUnique({
      where: { id: role_id },
    })

    if (!role) {
      throw new ValidationError('Invalid role')
    }

    // Create user
    const user = await database.user.create({
      data: {
        email,
        password_hash: password, // In production: hash password
        first_name,
        last_name,
        phone: phone || null,
        status: 'active',
      },
    })

    // Assign to company with role
    await database.userCompanyRole.create({
      data: {
        user_id: user.id,
        company_id: companyId,
        role_id,
      },
    })

    const response = successResponse({
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      phone: user.phone,
      status: user.status,
      created_at: user.created_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

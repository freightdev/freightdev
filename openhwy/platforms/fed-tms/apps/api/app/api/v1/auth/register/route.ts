/**
 * POST /api/v1/auth/register
 * User registration endpoint
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, ConflictError, AppError } from '@/lib/error-handler'
import { successResponse, errorResponse, HTTP_STATUS } from '@/lib/api-utils'
import { RegisterSchema } from '@/lib/validators'
import { logRequest } from '@/lib/middleware'

export async function POST(request: NextRequest) {
  try {
    logRequest(request)

    // Parse and validate request body
    const body = await request.json()
    const { email, password, first_name, last_name, company_name } = RegisterSchema.parse(body)

    // Check if user already exists
    const existingUser = await database.user.findUnique({
      where: { email },
    })

    if (existingUser) {
      throw new ConflictError('Email already registered')
    }

    // Create user
    const user = await database.user.create({
      data: {
        email,
        password_hash: password, // In production: hash password
        first_name,
        last_name,
        status: 'active',
      },
    })

    // Create company if provided
    let company = null
    if (company_name) {
      company = await database.company.create({
        data: {
          name: company_name,
          timezone: 'America/New_York',
        },
      })

      // Create admin role
      const adminRole = await database.role.findUnique({
        where: { name: 'admin' },
      })

      if (!adminRole) {
        throw new AppError('Admin role not found')
      }

      // Assign user to company with admin role
      await database.userCompanyRole.create({
        data: {
          user_id: user.id,
          company_id: company.id,
          role_id: adminRole.id,
        },
      })
    }

    const response = successResponse({
      user: {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
      },
      company: company && {
        id: company.id,
        name: company.name,
      },
      message: 'User registered successfully',
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

// Handle other methods
export async function GET() {
  return errorResponse('Method not allowed', HTTP_STATUS.INTERNAL_ERROR)
}

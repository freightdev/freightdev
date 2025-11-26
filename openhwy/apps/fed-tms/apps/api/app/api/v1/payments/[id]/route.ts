/**
 * GET /api/v1/payments/[id] - Get payment by ID
 * PUT /api/v1/payments/[id] - Update payment
 * DELETE /api/v1/payments/[id] - Delete payment
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError, ForbiddenError } from '@/lib/error-handler'
import { successResponse, HTTP_STATUS } from '@/lib/api-utils'
import { UpdatePaymentSchema } from '@/lib/validators'
import { requireAuth, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - Get payment by ID
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const payment = await database.payment.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
      include: {
        invoice: {
          select: {
            id: true,
            invoice_number: true,
            amount: true,
            status: true,
          },
        },
      },
    })

    if (!payment) {
      throw new NotFoundError('Payment not found')
    }

    return successResponse(payment)
  } catch (error) {
    return handleError(error)
  }
}

// PUT - Update payment
export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify payment exists and belongs to company
    const payment = await database.payment.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
    })

    if (!payment) {
      throw new NotFoundError('Payment not found')
    }

    // Prevent updating completed or refunded payments
    if (payment.status === 'completed' || payment.status === 'refunded') {
      throw new ForbiddenError(`Cannot update a ${payment.status} payment`)
    }

    const body = await request.json()
    const updates = UpdatePaymentSchema.parse(body)

    const updated = await database.payment.update({
      where: { id: params.id },
      data: updates,
      include: {
        invoice: {
          select: {
            id: true,
            invoice_number: true,
            amount: true,
            status: true,
          },
        },
      },
    })

    return successResponse(updated)
  } catch (error) {
    return handleError(error)
  }
}

// DELETE - Delete payment
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify payment exists
    const payment = await database.payment.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
    })

    if (!payment) {
      throw new NotFoundError('Payment not found')
    }

    // Prevent deleting completed or refunded payments
    if (payment.status === 'completed' || payment.status === 'refunded') {
      throw new ForbiddenError(`Cannot delete a ${payment.status} payment`)
    }

    // Delete payment
    await database.payment.delete({
      where: { id: params.id },
    })

    return successResponse({ message: 'Payment deleted successfully' })
  } catch (error) {
    return handleError(error)
  }
}

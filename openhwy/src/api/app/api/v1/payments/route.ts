/**
 * GET /api/v1/payments - List payments
 * POST /api/v1/payments - Create payment
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, ValidationError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { CreatePaymentSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

// GET - List payments with pagination
export async function GET(request: NextRequest) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()
    const { page, limit, skip, status } = getQueryParams(request)

    // Build where clause
    const where: any = { company_id: companyId }

    if (status) {
      where.status = status
    }

    // Get total count
    const total = await database.payment.count({ where })

    // Get paginated results
    const payments = await database.payment.findMany({
      where,
      include: {
        invoice: {
          select: {
            id: true,
            invoice_number: true,
            amount: true,
          },
        },
      },
      skip,
      take: limit,
      orderBy: { created_at: 'desc' },
    })

    return paginatedResponse(payments, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Create payment
export async function POST(request: NextRequest) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const body = await request.json()
    const { invoice_id, amount, method, transaction_id } = CreatePaymentSchema.parse(body)

    // Verify invoice exists if provided
    if (invoice_id) {
      const invoice = await database.invoice.findFirst({
        where: {
          id: invoice_id,
          company_id: companyId,
        },
      })

      if (!invoice) {
        throw new ValidationError('Invoice not found')
      }

      // Check if payment amount exceeds invoice amount
      const totalPaid = await database.payment.aggregate({
        where: {
          invoice_id,
          status: 'completed',
        },
        _sum: { amount: true },
      })

      const paid = totalPaid._sum.amount || 0
      if (paid + amount > invoice.amount) {
        throw new ValidationError('Payment amount exceeds invoice amount')
      }
    }

    // Create payment
    const payment = await database.payment.create({
      data: {
        company_id: companyId,
        invoice_id: invoice_id || null,
        amount,
        currency: 'USD',
        status: 'pending',
        method,
        transaction_id: transaction_id || null,
      },
    })

    const response = successResponse({
      id: payment.id,
      amount: payment.amount,
      method: payment.method,
      status: payment.status,
      created_at: payment.created_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

/**
 * GET /api/v1/invoices/[id] - Get invoice by ID
 * PUT /api/v1/invoices/[id] - Update invoice
 * DELETE /api/v1/invoices/[id] - Delete invoice
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, NotFoundError } from '@/lib/error-handler'
import { successResponse } from '@/lib/api-utils'
import { UpdateInvoiceSchema } from '@/lib/validators'
import { requireAuth, getCompanyContext } from '@/lib/middleware'

interface RouteParams {
  params: { id: string }
}

// GET - Get invoice by ID
export async function GET(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const invoice = await database.invoice.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
      include: {
        line_items: true,
        payments: true,
      },
    })

    if (!invoice) {
      throw new NotFoundError('Invoice not found')
    }

    // Calculate totals
    const totalPaid = invoice.payments
      .filter((p) => p.status === 'completed')
      .reduce((sum, p) => sum + p.amount, 0)

    return successResponse({
      ...invoice,
      totalPaid,
      remaining: invoice.amount - totalPaid,
    })
  } catch (error) {
    return handleError(error)
  }
}

// PUT - Update invoice
export async function PUT(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify invoice exists
    const invoice = await database.invoice.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
    })

    if (!invoice) {
      throw new NotFoundError('Invoice not found')
    }

    const body = await request.json()
    const updates = UpdateInvoiceSchema.parse(body)

    // Convert date strings if present
    const data: any = { ...updates }
    if (data.due_date) {
      data.due_date = new Date(data.due_date)
    }

    const updated = await database.invoice.update({
      where: { id: params.id },
      data,
      include: {
        line_items: true,
        payments: true,
      },
    })

    return successResponse(updated)
  } catch (error) {
    return handleError(error)
  }
}

// DELETE - Delete invoice
export async function DELETE(request: NextRequest, { params }: RouteParams) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    // Verify invoice exists
    const invoice = await database.invoice.findFirst({
      where: {
        id: params.id,
        company_id: companyId,
      },
    })

    if (!invoice) {
      throw new NotFoundError('Invoice not found')
    }

    // Delete invoice (cascade will handle related records)
    await database.invoice.delete({
      where: { id: params.id },
    })

    return successResponse({ message: 'Invoice deleted successfully' })
  } catch (error) {
    return handleError(error)
  }
}

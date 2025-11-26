/**
 * GET /api/v1/invoices - List invoices
 * POST /api/v1/invoices - Create invoice
 */

import { database } from '@repo/database'
import { NextRequest } from 'next/server'
import { handleError, ValidationError } from '@/lib/error-handler'
import { successResponse, paginatedResponse, HTTP_STATUS } from '@/lib/api-utils'
import { CreateInvoiceSchema } from '@/lib/validators'
import { requireAuth, getQueryParams, getCompanyContext } from '@/lib/middleware'

// GET - List invoices with pagination
export async function GET(request: NextRequest) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()
    const { page, limit, skip, search, status, startDate, endDate } = getQueryParams(request)

    // Build where clause
    const where: any = { company_id: companyId }

    if (search) {
      where.invoice_number = { contains: search, mode: 'insensitive' }
    }

    if (status) {
      where.status = status
    }

    if (startDate || endDate) {
      where.issued_date = {}
      if (startDate) where.issued_date.gte = new Date(startDate)
      if (endDate) where.issued_date.lte = new Date(endDate)
    }

    // Get total count
    const total = await database.invoice.count({ where })

    // Get paginated results
    const invoices = await database.invoice.findMany({
      where,
      include: {
        line_items: true,
        payments: true,
      },
      skip,
      take: limit,
      orderBy: { created_at: 'desc' },
    })

    return paginatedResponse(invoices, total, page, limit)
  } catch (error) {
    return handleError(error)
  }
}

// POST - Create invoice
export async function POST(request: NextRequest) {
  try {
    await requireAuth(request)
    const { companyId } = await getCompanyContext()

    const body = await request.json()
    const { invoice_number, driver_id, load_id, amount, due_date, description, notes } =
      CreateInvoiceSchema.parse(body)

    // Check if invoice number is unique within company
    const existingInvoice = await database.invoice.findFirst({
      where: {
        invoice_number,
        company_id: companyId,
      },
    })

    if (existingInvoice) {
      throw new ValidationError('Invoice with this number already exists')
    }

    // Verify driver exists if provided
    if (driver_id) {
      const driver = await database.driver.findFirst({
        where: {
          id: driver_id,
          company_id: companyId,
        },
      })

      if (!driver) {
        throw new ValidationError('Driver not found')
      }
    }

    // Verify load exists if provided
    if (load_id) {
      const load = await database.load.findFirst({
        where: {
          id: load_id,
          company_id: companyId,
        },
      })

      if (!load) {
        throw new ValidationError('Load not found')
      }
    }

    // Create invoice
    const invoice = await database.invoice.create({
      data: {
        company_id: companyId,
        invoice_number,
        driver_id: driver_id || null,
        load_id: load_id || null,
        amount,
        currency: 'USD',
        status: 'pending',
        issued_date: new Date(),
        due_date: new Date(due_date),
        description: description || null,
        notes: notes || null,
      },
    })

    const response = successResponse({
      id: invoice.id,
      invoice_number: invoice.invoice_number,
      amount: invoice.amount,
      status: invoice.status,
      due_date: invoice.due_date,
      created_at: invoice.created_at,
    })

    response.status = HTTP_STATUS.CREATED
    return response
  } catch (error) {
    return handleError(error)
  }
}

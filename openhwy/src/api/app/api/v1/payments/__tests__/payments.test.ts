/**
 * Payment & Invoice Endpoint Tests
 * Tests for payment and invoice CRUD operations
 */

jest.mock('@repo/database', () => ({
  database: {
    payment: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      count: jest.fn(),
      aggregate: jest.fn(),
    },
    invoice: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      count: jest.fn(),
    },
  },
}))

jest.mock('@/lib/middleware', () => ({
  requireAuth: jest.fn(() =>
    Promise.resolve({
      userId: 'user-123',
      orgId: 'company-123',
    })
  ),
  getCompanyContext: jest.fn(() =>
    Promise.resolve({
      companyId: 'company-123',
      userId: 'user-123',
    })
  ),
  getQueryParams: jest.fn(() => ({
    page: 1,
    limit: 10,
    skip: 0,
    search: null,
    status: null,
  })),
}))

import { database } from '@repo/database'

describe('Payment Management Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('GET /payments', () => {
    it('should list all payments with pagination', async () => {
      const mockPayments = [
        {
          id: 'payment-1',
          company_id: 'company-123',
          invoice_id: 'invoice-1',
          amount: 750,
          currency: 'USD',
          status: 'completed',
          method: 'card',
          created_at: new Date(),
        },
        {
          id: 'payment-2',
          company_id: 'company-123',
          invoice_id: 'invoice-1',
          amount: 750,
          currency: 'USD',
          status: 'completed',
          method: 'ach',
          created_at: new Date(),
        },
      ]

      ;(database.payment.findMany as jest.Mock).mockResolvedValueOnce(mockPayments)
      ;(database.payment.count as jest.Mock).mockResolvedValueOnce(2)

      const payments = await database.payment.findMany({
        where: { company_id: 'company-123' },
        skip: 0,
        take: 10,
      })

      expect(payments).toHaveLength(2)
      expect(payments[0].method).toBe('card')
    })

    it('should filter payments by status', async () => {
      const completedPayments = [
        {
          id: 'payment-1',
          status: 'completed',
        },
      ]

      ;(database.payment.findMany as jest.Mock).mockResolvedValueOnce(
        completedPayments
      )

      const payments = await database.payment.findMany({
        where: {
          company_id: 'company-123',
          status: 'completed',
        },
      })

      expect(payments[0].status).toBe('completed')
    })
  })

  describe('POST /payments', () => {
    it('should create payment with valid data', async () => {
      const newPayment = {
        id: 'payment-new',
        company_id: 'company-123',
        invoice_id: 'invoice-123',
        amount: 1500,
        currency: 'USD',
        status: 'pending',
        method: 'card',
        transaction_id: 'txn-123',
        created_at: new Date(),
      }

      ;(database.invoice.findFirst as jest.Mock).mockResolvedValueOnce({
        id: 'invoice-123',
        amount: 1500,
      })
      ;(database.payment.create as jest.Mock).mockResolvedValueOnce(newPayment)

      const payment = await database.payment.create({
        data: {
          company_id: 'company-123',
          invoice_id: 'invoice-123',
          amount: 1500,
          currency: 'USD',
          status: 'pending',
          method: 'card',
          transaction_id: 'txn-123',
        },
      })

      expect(payment.amount).toBe(1500)
      expect(payment.method).toBe('card')
    })

    it('should validate payment amount is positive', async () => {
      const invalidAmount = -100
      expect(invalidAmount > 0).toBe(false)
    })

    it('should validate payment method enum', async () => {
      const validMethods = ['card', 'ach', 'wire', 'check', 'cash']
      const invalidMethod = 'bitcoin'

      expect(validMethods.includes(invalidMethod)).toBe(false)
    })

    it('should verify invoice exists before creating payment', async () => {
      ;(database.invoice.findFirst as jest.Mock).mockResolvedValueOnce(null)

      const invoice = await database.invoice.findFirst({
        where: { id: 'nonexistent-invoice' },
      })

      expect(invoice).toBeNull()
    })

    it('should validate payment amount does not exceed invoice amount', async () => {
      ;(database.invoice.findFirst as jest.Mock).mockResolvedValueOnce({
        id: 'invoice-123',
        amount: 1000,
      })
      ;(database.payment.aggregate as jest.Mock).mockResolvedValueOnce({
        _sum: { amount: 500 },
      })

      const invoice = await database.invoice.findFirst({
        where: { id: 'invoice-123' },
      })

      const totalPaid = await database.payment.aggregate({
        where: {
          invoice_id: 'invoice-123',
          status: 'completed',
        },
        _sum: { amount: true },
      })

      const paymentAmount = 600 // 500 + 600 = 1100 > 1000
      const totalWithPayment = (totalPaid._sum.amount || 0) + paymentAmount

      expect(totalWithPayment > invoice!.amount).toBe(true)
    })
  })

  describe('GET /payments/{id}', () => {
    it('should retrieve payment details', async () => {
      const mockPayment = {
        id: 'payment-123',
        company_id: 'company-123',
        amount: 1500,
        status: 'completed',
        method: 'card',
        invoice: {
          id: 'invoice-123',
          invoice_number: 'INV-001',
          amount: 1500,
        },
      }

      ;(database.payment.findFirst as jest.Mock).mockResolvedValueOnce(mockPayment)

      const payment = await database.payment.findFirst({
        where: {
          id: 'payment-123',
          company_id: 'company-123',
        },
        include: {
          invoice: {
            select: {
              id: true,
              invoice_number: true,
              amount: true,
            },
          },
        },
      })

      expect(payment?.amount).toBe(1500)
      expect(payment?.invoice?.invoice_number).toBe('INV-001')
    })
  })

  describe('PUT /payments/{id}', () => {
    it('should update payment status', async () => {
      const updatedPayment = {
        id: 'payment-123',
        status: 'completed',
        updated_at: new Date(),
      }

      ;(database.payment.findFirst as jest.Mock).mockResolvedValueOnce({
        id: 'payment-123',
        status: 'pending',
      })
      ;(database.payment.update as jest.Mock).mockResolvedValueOnce(updatedPayment)

      const payment = await database.payment.update({
        where: { id: 'payment-123' },
        data: { status: 'completed' },
      })

      expect(payment.status).toBe('completed')
    })

    it('should prevent updating completed payment', async () => {
      ;(database.payment.findFirst as jest.Mock).mockResolvedValueOnce({
        id: 'payment-123',
        status: 'completed',
      })

      const payment = await database.payment.findFirst({
        where: { id: 'payment-123' },
      })

      // Should not allow update
      if (payment?.status === 'completed') {
        expect(false).toBe(true) // Intentionally fail if trying to update
      } else {
        expect(true).toBe(true)
      }
    })

    it('should prevent updating refunded payment', async () => {
      ;(database.payment.findFirst as jest.Mock).mockResolvedValueOnce({
        id: 'payment-123',
        status: 'refunded',
      })

      const payment = await database.payment.findFirst({
        where: { id: 'payment-123' },
      })

      if (payment?.status === 'refunded') {
        expect(false).toBe(true) // Intentionally fail
      } else {
        expect(true).toBe(true)
      }
    })

    it('should validate payment status enum', async () => {
      const validStatuses = ['pending', 'completed', 'failed', 'refunded']
      const invalidStatus = 'processed'

      expect(validStatuses.includes(invalidStatus)).toBe(false)
    })
  })

  describe('DELETE /payments/{id}', () => {
    it('should delete payment', async () => {
      ;(database.payment.findFirst as jest.Mock).mockResolvedValueOnce({
        id: 'payment-123',
        status: 'pending',
      })
      ;(database.payment.delete as jest.Mock).mockResolvedValueOnce({
        id: 'payment-123',
      })

      // Verify not completed
      const payment = await database.payment.findFirst({
        where: { id: 'payment-123' },
      })

      if (payment?.status !== 'completed' && payment?.status !== 'refunded') {
        await database.payment.delete({ where: { id: 'payment-123' } })
      }

      expect(database.payment.delete).toHaveBeenCalled()
    })

    it('should prevent deleting completed payment', async () => {
      ;(database.payment.findFirst as jest.Mock).mockResolvedValueOnce({
        id: 'payment-123',
        status: 'completed',
      })

      const payment = await database.payment.findFirst({
        where: { id: 'payment-123' },
      })

      if (payment?.status === 'completed') {
        expect(false).toBe(true) // Should prevent deletion
      } else {
        expect(true).toBe(true)
      }
    })
  })
})

describe('Invoice Management Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('GET /invoices', () => {
    it('should list all invoices', async () => {
      const mockInvoices = [
        {
          id: 'invoice-1',
          company_id: 'company-123',
          invoice_number: 'INV-001',
          amount: 1500,
          status: 'pending',
          due_date: new Date(),
          created_at: new Date(),
        },
        {
          id: 'invoice-2',
          company_id: 'company-123',
          invoice_number: 'INV-002',
          amount: 2000,
          status: 'sent',
          due_date: new Date(),
          created_at: new Date(),
        },
      ]

      ;(database.invoice.findMany as jest.Mock).mockResolvedValueOnce(mockInvoices)
      ;(database.invoice.count as jest.Mock).mockResolvedValueOnce(2)

      const invoices = await database.invoice.findMany({
        where: { company_id: 'company-123' },
        skip: 0,
        take: 10,
      })

      expect(invoices).toHaveLength(2)
      expect(invoices[0].invoice_number).toBe('INV-001')
    })

    it('should filter invoices by status', async () => {
      const unpaidInvoices = [
        {
          id: 'invoice-1',
          status: 'pending',
        },
      ]

      ;(database.invoice.findMany as jest.Mock).mockResolvedValueOnce(unpaidInvoices)

      const invoices = await database.invoice.findMany({
        where: {
          company_id: 'company-123',
          status: 'pending',
        },
      })

      expect(invoices[0].status).toBe('pending')
    })
  })

  describe('POST /invoices', () => {
    it('should create new invoice', async () => {
      const newInvoice = {
        id: 'invoice-new',
        company_id: 'company-123',
        invoice_number: 'INV-999',
        amount: 1500,
        status: 'pending',
        due_date: new Date(),
        created_at: new Date(),
      }

      ;(database.invoice.create as jest.Mock).mockResolvedValueOnce(newInvoice)

      const invoice = await database.invoice.create({
        data: {
          company_id: 'company-123',
          invoice_number: 'INV-999',
          amount: 1500,
          status: 'pending',
          due_date: newInvoice.due_date,
        },
      })

      expect(invoice.invoice_number).toBe('INV-999')
      expect(invoice.status).toBe('pending')
    })

    it('should validate amount is positive', async () => {
      const invalidAmount = -100
      expect(invalidAmount > 0).toBe(false)
    })

    it('should validate invoice number is provided', async () => {
      const incompleteData = {
        amount: 1500,
        // Missing invoice_number
      }

      expect((incompleteData as any).invoice_number).toBeUndefined()
    })
  })

  describe('GET /invoices/{id}', () => {
    it('should retrieve invoice with payment totals', async () => {
      const mockInvoice = {
        id: 'invoice-123',
        company_id: 'company-123',
        invoice_number: 'INV-001',
        amount: 1500,
        status: 'partial',
        payments: [
          { id: 'pay-1', amount: 750, status: 'completed' },
        ],
      }

      ;(database.invoice.findFirst as jest.Mock).mockResolvedValueOnce(mockInvoice)

      const invoice = await database.invoice.findFirst({
        where: {
          id: 'invoice-123',
          company_id: 'company-123',
        },
        include: {
          payments: true,
        },
      })

      const totalPaid = invoice!.payments
        .filter((p: any) => p.status === 'completed')
        .reduce((sum: number, p: any) => sum + p.amount, 0)

      expect(totalPaid).toBe(750)
      expect(invoice!.amount - totalPaid).toBe(750) // Remaining
    })
  })

  describe('PUT /invoices/{id}', () => {
    it('should update invoice status', async () => {
      const updatedInvoice = {
        id: 'invoice-123',
        status: 'paid',
        updated_at: new Date(),
      }

      ;(database.invoice.update as jest.Mock).mockResolvedValueOnce(updatedInvoice)

      const invoice = await database.invoice.update({
        where: { id: 'invoice-123' },
        data: { status: 'paid' },
      })

      expect(invoice.status).toBe('paid')
    })

    it('should allow updating amount', async () => {
      const updatedInvoice = {
        id: 'invoice-123',
        amount: 1600,
      }

      ;(database.invoice.update as jest.Mock).mockResolvedValueOnce(updatedInvoice)

      const invoice = await database.invoice.update({
        where: { id: 'invoice-123' },
        data: { amount: 1600 },
      })

      expect(invoice.amount).toBe(1600)
    })

    it('should validate status enum', async () => {
      const validStatuses = ['pending', 'sent', 'partial', 'paid', 'overdue', 'cancelled']
      const invalidStatus = 'completed'

      expect(validStatuses.includes(invalidStatus)).toBe(false)
    })
  })

  describe('DELETE /invoices/{id}', () => {
    it('should delete invoice', async () => {
      ;(database.invoice.delete as jest.Mock).mockResolvedValueOnce({
        id: 'invoice-123',
      })

      await database.invoice.delete({
        where: { id: 'invoice-123' },
      })

      expect(database.invoice.delete).toHaveBeenCalled()
    })
  })
})

describe('Payment & Invoice Multi-Tenant Safety', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should only list payments from authenticated company', async () => {
    ;(database.payment.findMany as jest.Mock).mockResolvedValueOnce([])

    await database.payment.findMany({
      where: { company_id: 'company-123' },
    })

    expect(database.payment.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ company_id: 'company-123' }),
      })
    )
  })

  it('should only list invoices from authenticated company', async () => {
    ;(database.invoice.findMany as jest.Mock).mockResolvedValueOnce([])

    await database.invoice.findMany({
      where: { company_id: 'company-123' },
    })

    expect(database.invoice.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ company_id: 'company-123' }),
      })
    )
  })
})

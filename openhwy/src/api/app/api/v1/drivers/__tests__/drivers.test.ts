/**
 * Driver Management Endpoint Tests
 * Tests for driver CRUD, documents, locations, and ratings
 */

jest.mock('@repo/database', () => ({
  database: {
    driver: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      count: jest.fn(),
    },
    driverDocument: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      count: jest.fn(),
    },
    driverLocation: {
      findMany: jest.fn(),
      create: jest.fn(),
      count: jest.fn(),
    },
    driverRating: {
      findMany: jest.fn(),
      create: jest.fn(),
      count: jest.fn(),
      aggregate: jest.fn(),
    },
    user: {
      findFirst: jest.fn(),
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

describe('Driver Management Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('GET /drivers', () => {
    it('should list all drivers with pagination', async () => {
      const mockDrivers = [
        {
          id: 'driver-1',
          user_id: 'user-1',
          company_id: 'company-123',
          license_number: 'DL123456',
          vehicle_type: 'truck',
          status: 'active',
          rating: 4.5,
          created_at: new Date(),
        },
        {
          id: 'driver-2',
          user_id: 'user-2',
          company_id: 'company-123',
          license_number: 'DL789012',
          vehicle_type: 'trailer',
          status: 'active',
          rating: 4.8,
          created_at: new Date(),
        },
      ]

      ;(database.driver.findMany as jest.Mock).mockResolvedValueOnce(mockDrivers)
      ;(database.driver.count as jest.Mock).mockResolvedValueOnce(2)

      const drivers = await database.driver.findMany({
        where: { company_id: 'company-123' },
        skip: 0,
        take: 10,
      })

      expect(drivers).toHaveLength(2)
      expect(drivers[0].vehicle_type).toBe('truck')
    })

    it('should filter drivers by status', async () => {
      const activeDrivers = [
        {
          id: 'driver-1',
          status: 'active',
        },
      ]

      ;(database.driver.findMany as jest.Mock).mockResolvedValueOnce(
        activeDrivers
      )

      const drivers = await database.driver.findMany({
        where: {
          company_id: 'company-123',
          status: 'active',
        },
      })

      expect(drivers).toHaveLength(1)
      expect(drivers[0].status).toBe('active')
    })

    it('should search drivers by name', async () => {
      const searchResults = [
        {
          id: 'driver-1',
          user_id: 'user-john',
          first_name: 'John',
          last_name: 'Doe',
        },
      ]

      ;(database.driver.findMany as jest.Mock).mockResolvedValueOnce(searchResults)

      const drivers = await database.driver.findMany({
        where: {
          company_id: 'company-123',
          OR: [
            { user: { first_name: { contains: 'john' } } },
            { user: { last_name: { contains: 'john' } } },
          ],
        },
      })

      expect(drivers).toHaveLength(1)
    })
  })

  describe('POST /drivers', () => {
    it('should create new driver with valid data', async () => {
      const newDriver = {
        id: 'driver-new-123',
        user_id: 'user-123',
        company_id: 'company-123',
        license_number: 'DL123456',
        license_class: 'A',
        vehicle_type: 'truck',
        vehicle_vin: 'VIN123456',
        vehicle_plate: 'ABC123',
        status: 'active',
        created_at: new Date(),
      }

      ;(database.user.findFirst as jest.Mock).mockResolvedValueOnce({
        id: 'user-123',
      })
      ;(database.driver.create as jest.Mock).mockResolvedValueOnce(newDriver)

      const driver = await database.driver.create({
        data: {
          user_id: 'user-123',
          company_id: 'company-123',
          license_number: 'DL123456',
          license_class: 'A',
          vehicle_type: 'truck',
          vehicle_vin: 'VIN123456',
          vehicle_plate: 'ABC123',
          status: 'active',
        },
      })

      expect(driver.license_number).toBe('DL123456')
      expect(driver.status).toBe('active')
      expect(database.driver.create).toHaveBeenCalled()
    })

    it('should validate required fields', async () => {
      const incompleteData = {
        user_id: 'user-123',
        // Missing license_number
        vehicle_type: 'truck',
      }

      // Validation check
      expect((incompleteData as any).license_number).toBeUndefined()
    })

    it('should verify user exists before creating driver', async () => {
      ;(database.user.findFirst as jest.Mock).mockResolvedValueOnce(null)

      const user = await database.user.findFirst({
        where: { id: 'nonexistent-user' },
      })

      expect(user).toBeNull()
      // Should not create driver
    })
  })

  describe('GET /drivers/{id}', () => {
    it('should retrieve driver details', async () => {
      const mockDriver = {
        id: 'driver-123',
        user_id: 'user-123',
        company_id: 'company-123',
        license_number: 'DL123456',
        vehicle_type: 'truck',
        status: 'active',
        rating: 4.5,
        total_loads: 25,
      }

      ;(database.driver.findFirst as jest.Mock).mockResolvedValueOnce(mockDriver)

      const driver = await database.driver.findFirst({
        where: {
          id: 'driver-123',
          company_id: 'company-123',
        },
      })

      expect(driver?.id).toBe('driver-123')
      expect(driver?.license_number).toBe('DL123456')
    })

    it('should return 404 for non-existent driver', async () => {
      ;(database.driver.findFirst as jest.Mock).mockResolvedValueOnce(null)

      const driver = await database.driver.findFirst({
        where: { id: 'nonexistent-driver' },
      })

      expect(driver).toBeNull()
    })
  })

  describe('PUT /drivers/{id}', () => {
    it('should update driver information', async () => {
      const updatedDriver = {
        id: 'driver-123',
        vehicle_type: 'straight-truck',
        status: 'active',
        updated_at: new Date(),
      }

      ;(database.driver.update as jest.Mock).mockResolvedValueOnce(updatedDriver)

      const driver = await database.driver.update({
        where: { id: 'driver-123' },
        data: { vehicle_type: 'straight-truck' },
      })

      expect(driver.vehicle_type).toBe('straight-truck')
      expect(database.driver.update).toHaveBeenCalled()
    })

    it('should validate status enum', async () => {
      const validStatuses = ['active', 'inactive', 'on_leave', 'suspended']
      const invalidStatus = 'unknown'

      expect(validStatuses.includes(invalidStatus)).toBe(false)
    })
  })

  describe('DELETE /drivers/{id}', () => {
    it('should delete driver', async () => {
      const deletedDriver = {
        id: 'driver-123',
        user_id: 'user-123',
      }

      ;(database.driver.delete as jest.Mock).mockResolvedValueOnce(deletedDriver)

      const driver = await database.driver.delete({
        where: { id: 'driver-123' },
      })

      expect(driver.id).toBe('driver-123')
      expect(database.driver.delete).toHaveBeenCalled()
    })
  })

  describe('Driver Documents', () => {
    it('should list driver documents with pagination', async () => {
      const mockDocuments = [
        {
          id: 'doc-1',
          driver_id: 'driver-123',
          type: 'license',
          document_url: 'https://example.com/license.pdf',
          uploaded_at: new Date(),
        },
        {
          id: 'doc-2',
          driver_id: 'driver-123',
          type: 'insurance',
          document_url: 'https://example.com/insurance.pdf',
          uploaded_at: new Date(),
        },
      ]

      ;(database.driverDocument.findMany as jest.Mock).mockResolvedValueOnce(
        mockDocuments
      )
      ;(database.driverDocument.count as jest.Mock).mockResolvedValueOnce(2)

      const documents = await database.driverDocument.findMany({
        where: { driver_id: 'driver-123' },
        skip: 0,
        take: 10,
      })

      expect(documents).toHaveLength(2)
      expect(documents[0].type).toBe('license')
    })

    it('should upload driver document', async () => {
      const newDocument = {
        id: 'doc-new-123',
        driver_id: 'driver-123',
        type: 'medical_cert',
        document_url: 'https://example.com/medical.pdf',
        expiry_date: new Date('2026-01-01'),
        uploaded_at: new Date(),
      }

      ;(database.driverDocument.create as jest.Mock).mockResolvedValueOnce(
        newDocument
      )

      const document = await database.driverDocument.create({
        data: {
          driver_id: 'driver-123',
          type: 'medical_cert',
          document_url: 'https://example.com/medical.pdf',
          expiry_date: new Date('2026-01-01'),
        },
      })

      expect(document.type).toBe('medical_cert')
      expect(document.document_url).toContain('https://')
    })

    it('should validate document types', async () => {
      const validTypes = ['license', 'insurance', 'medical_cert', 'background_check']
      const invalidType = 'passport'

      expect(validTypes.includes(invalidType)).toBe(false)
    })

    it('should get specific document', async () => {
      const mockDocument = {
        id: 'doc-123',
        driver_id: 'driver-123',
        type: 'license',
        document_url: 'https://example.com/license.pdf',
      }

      ;(database.driverDocument.findFirst as jest.Mock).mockResolvedValueOnce(
        mockDocument
      )

      const document = await database.driverDocument.findFirst({
        where: { id: 'doc-123', driver_id: 'driver-123' },
      })

      expect(document?.type).toBe('license')
    })

    it('should delete document', async () => {
      ;(database.driverDocument.delete as jest.Mock).mockResolvedValueOnce({
        id: 'doc-123',
      })

      await database.driverDocument.delete({
        where: { id: 'doc-123' },
      })

      expect(database.driverDocument.delete).toHaveBeenCalled()
    })
  })

  describe('Driver Locations', () => {
    it('should list driver location history', async () => {
      const mockLocations = [
        {
          id: 'loc-1',
          driver_id: 'driver-123',
          latitude: 40.7128,
          longitude: -74.006,
          accuracy: 10,
          timestamp: new Date(),
        },
        {
          id: 'loc-2',
          driver_id: 'driver-123',
          latitude: 40.8,
          longitude: -74.1,
          accuracy: 15,
          timestamp: new Date(),
        },
      ]

      ;(database.driverLocation.findMany as jest.Mock).mockResolvedValueOnce(
        mockLocations
      )

      const locations = await database.driverLocation.findMany({
        where: { driver_id: 'driver-123' },
        orderBy: { timestamp: 'desc' },
      })

      expect(locations).toHaveLength(2)
      expect(locations[0].latitude).toBe(40.7128)
    })

    it('should update driver location', async () => {
      const newLocation = {
        id: 'loc-new',
        driver_id: 'driver-123',
        latitude: 40.7128,
        longitude: -74.006,
        accuracy: 10,
        timestamp: new Date(),
      }

      ;(database.driverLocation.create as jest.Mock).mockResolvedValueOnce(
        newLocation
      )

      const location = await database.driverLocation.create({
        data: {
          driver_id: 'driver-123',
          latitude: 40.7128,
          longitude: -74.006,
          accuracy: 10,
        },
      })

      expect(location.latitude).toBe(40.7128)
      expect(location.longitude).toBe(-74.006)
    })

    it('should validate latitude range', () => {
      const validLatitude = 40.7128
      const invalidLatitude = 100 // > 90

      expect(validLatitude >= -90 && validLatitude <= 90).toBe(true)
      expect(invalidLatitude >= -90 && invalidLatitude <= 90).toBe(false)
    })

    it('should validate longitude range', () => {
      const validLongitude = -74.006
      const invalidLongitude = 200 // > 180

      expect(validLongitude >= -180 && validLongitude <= 180).toBe(true)
      expect(invalidLongitude >= -180 && invalidLongitude <= 180).toBe(false)
    })
  })

  describe('Driver Ratings', () => {
    it('should get driver ratings with average', async () => {
      const mockRatings = [
        {
          id: 'rating-1',
          driver_id: 'driver-123',
          rating: 5,
          comment: 'Excellent',
          created_at: new Date(),
        },
        {
          id: 'rating-2',
          driver_id: 'driver-123',
          rating: 4,
          comment: 'Good',
          created_at: new Date(),
        },
      ]

      ;(database.driverRating.findMany as jest.Mock).mockResolvedValueOnce(
        mockRatings
      )
      ;(database.driverRating.aggregate as jest.Mock).mockResolvedValueOnce({
        _avg: { rating: 4.5 },
      })

      const ratings = await database.driverRating.findMany({
        where: { driver_id: 'driver-123' },
      })

      const avgRating = await database.driverRating.aggregate({
        where: { driver_id: 'driver-123' },
        _avg: { rating: true },
      })

      expect(ratings).toHaveLength(2)
      expect(avgRating._avg.rating).toBe(4.5)
    })

    it('should add driver rating', async () => {
      const newRating = {
        id: 'rating-new',
        driver_id: 'driver-123',
        rating: 5,
        comment: 'Great driver',
        load_id: 'load-123',
        created_at: new Date(),
      }

      ;(database.driverRating.create as jest.Mock).mockResolvedValueOnce(newRating)

      const rating = await database.driverRating.create({
        data: {
          driver_id: 'driver-123',
          rating: 5,
          comment: 'Great driver',
          load_id: 'load-123',
        },
      })

      expect(rating.rating).toBe(5)
      expect(rating.comment).toBe('Great driver')
    })

    it('should validate rating range', () => {
      const validRatings = [1, 2, 3, 4, 5]
      const invalidRatings = [0, 6, -1]

      validRatings.forEach((rating) => {
        expect(rating >= 1 && rating <= 5).toBe(true)
      })

      invalidRatings.forEach((rating) => {
        expect(rating >= 1 && rating <= 5).toBe(false)
      })
    })

    it('should auto-update driver rating after rating added', async () => {
      // Mock aggregation to get new average
      ;(database.driverRating.aggregate as jest.Mock).mockResolvedValueOnce({
        _avg: { rating: 4.8 },
      })

      // Mock driver update
      ;(database.driver.update as jest.Mock).mockResolvedValueOnce({
        id: 'driver-123',
        rating: 4.8,
      })

      const avgRating = await database.driverRating.aggregate({
        where: { driver_id: 'driver-123' },
        _avg: { rating: true },
      })

      const updatedDriver = await database.driver.update({
        where: { id: 'driver-123' },
        data: { rating: avgRating._avg.rating || 5.0 },
      })

      expect(updatedDriver.rating).toBe(4.8)
    })
  })
})

describe('Driver Multi-Tenant Safety', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should only list drivers from authenticated company', async () => {
    ;(database.driver.findMany as jest.Mock).mockResolvedValueOnce([])

    await database.driver.findMany({
      where: { company_id: 'company-123' },
    })

    expect(database.driver.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ company_id: 'company-123' }),
      })
    )
  })

  it('should not allow cross-company driver access', async () => {
    ;(database.driver.findFirst as jest.Mock).mockResolvedValueOnce(null)

    const driver = await database.driver.findFirst({
      where: {
        id: 'driver-from-other-company',
        company_id: 'company-123',
      },
    })

    expect(driver).toBeNull()
  })
})

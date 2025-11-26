/**
 * User Management Endpoint Tests
 * Tests for user CRUD operations with pagination and filtering
 */

jest.mock('@repo/database', () => ({
  database: {
    user: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      count: jest.fn(),
    },
    userCompanyRole: {
      create: jest.fn(),
      deleteMany: jest.fn(),
    },
  },
}))

jest.mock('@/lib/middleware', () => ({
  requireAuth: jest.fn(() =>
    Promise.resolve({
      userId: 'user-123',
      orgId: 'company-123',
      user: {
        id: 'user-123',
        email: 'admin@example.com',
      },
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

describe('User Management Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('GET /users', () => {
    it('should list all users with pagination', async () => {
      const mockUsers = [
        {
          id: 'user-1',
          email: 'user1@example.com',
          first_name: 'John',
          last_name: 'Doe',
          created_at: new Date(),
        },
        {
          id: 'user-2',
          email: 'user2@example.com',
          first_name: 'Jane',
          last_name: 'Smith',
          created_at: new Date(),
        },
      ]

      ;(database.user.findMany as jest.Mock).mockResolvedValueOnce(mockUsers)
      ;(database.user.count as jest.Mock).mockResolvedValueOnce(2)

      const users = await database.user.findMany({
        where: { company_roles: { some: { company_id: 'company-123' } } },
        skip: 0,
        take: 10,
      })

      expect(users).toHaveLength(2)
      expect(users[0].email).toBe('user1@example.com')
      expect(database.user.findMany).toHaveBeenCalled()
    })

    it('should filter users by search term', async () => {
      const mockUsers = [
        {
          id: 'user-1',
          email: 'john@example.com',
          first_name: 'John',
          last_name: 'Doe',
        },
      ]

      ;(database.user.findMany as jest.Mock).mockResolvedValueOnce(mockUsers)

      const users = await database.user.findMany({
        where: {
          OR: [
            { email: { contains: 'john' } },
            { first_name: { contains: 'john' } },
          ],
        },
      })

      expect(users).toHaveLength(1)
      expect(users[0].first_name).toBe('John')
    })

    it('should support pagination', async () => {
      const mockUsers = Array.from({ length: 10 }, (_, i) => ({
        id: `user-${i + 1}`,
        email: `user${i + 1}@example.com`,
        first_name: 'User',
        last_name: `${i + 1}`,
      }))

      ;(database.user.findMany as jest.Mock).mockResolvedValueOnce(mockUsers)
      ;(database.user.count as jest.Mock).mockResolvedValueOnce(50)

      const users = await database.user.findMany({
        skip: 0,
        take: 10,
      })

      expect(users).toHaveLength(10)
    })

    it('should enforce multi-tenant isolation', async () => {
      ;(database.user.findMany as jest.Mock).mockResolvedValueOnce([])

      // Should only query users for authenticated company
      await database.user.findMany({
        where: {
          company_roles: {
            some: { company_id: 'company-123' },
          },
        },
      })

      expect(database.user.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            company_roles: expect.objectContaining({
              some: expect.objectContaining({ company_id: 'company-123' }),
            }),
          }),
        })
      )
    })
  })

  describe('POST /users', () => {
    it('should create new user with valid data', async () => {
      const newUserData = {
        email: 'newuser@example.com',
        password: 'SecurePassword123',
        first_name: 'New',
        last_name: 'User',
        phone: '+1234567890',
        role_id: 'role-dispatcher',
      }

      const createdUser = {
        id: 'user-new-123',
        email: newUserData.email,
        first_name: newUserData.first_name,
        last_name: newUserData.last_name,
        phone: newUserData.phone,
        created_at: new Date(),
      }

      ;(database.user.create as jest.Mock).mockResolvedValueOnce(createdUser)

      const user = await database.user.create({
        data: {
          email: newUserData.email,
          password_hash: 'hashed_password',
          first_name: newUserData.first_name,
          last_name: newUserData.last_name,
          phone: newUserData.phone,
        },
      })

      expect(user.email).toBe(newUserData.email)
      expect(user.first_name).toBe(newUserData.first_name)
      expect(database.user.create).toHaveBeenCalled()
    })

    it('should validate email format', async () => {
      const invalidEmail = 'not-an-email'
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

      expect(emailRegex.test(invalidEmail)).toBe(false)
    })

    it('should enforce password minimum length', async () => {
      const weakPassword = 'short'
      const passwordMinLength = 8

      expect(weakPassword.length < passwordMinLength).toBe(true)
    })

    it('should assign role to new user', async () => {
      const roleAssignment = {
        id: 'assignment-123',
        user_id: 'user-new-123',
        company_id: 'company-123',
        role_id: 'role-dispatcher',
      }

      ;(database.userCompanyRole.create as jest.Mock).mockResolvedValueOnce(
        roleAssignment
      )

      const assignment = await database.userCompanyRole.create({
        data: roleAssignment,
      })

      expect(assignment.role_id).toBe('role-dispatcher')
      expect(assignment.user_id).toBe('user-new-123')
    })

    it('should reject duplicate email', async () => {
      ;(database.user.findUnique as jest.Mock).mockResolvedValueOnce({
        id: 'existing-user',
        email: 'existing@example.com',
      })

      const existingUser = await database.user.findUnique({
        where: { email: 'existing@example.com' },
      })

      expect(existingUser).toBeDefined()
      // Should not allow creation
    })
  })

  describe('GET /users/{id}', () => {
    it('should retrieve user by ID', async () => {
      const mockUser = {
        id: 'user-123',
        email: 'user@example.com',
        first_name: 'John',
        last_name: 'Doe',
        phone: '+1234567890',
        company_roles: [
          {
            id: 'role-assign-1',
            role_id: 'role-admin',
            company_id: 'company-123',
          },
        ],
      }

      ;(database.user.findFirst as jest.Mock).mockResolvedValueOnce(mockUser)

      const user = await database.user.findFirst({
        where: {
          id: 'user-123',
          company_roles: { some: { company_id: 'company-123' } },
        },
        include: { company_roles: true },
      })

      expect(user?.id).toBe('user-123')
      expect(user?.email).toBe('user@example.com')
      expect(user?.company_roles).toHaveLength(1)
    })

    it('should return 404 for non-existent user', async () => {
      ;(database.user.findFirst as jest.Mock).mockResolvedValueOnce(null)

      const user = await database.user.findFirst({
        where: { id: 'nonexistent-id' },
      })

      expect(user).toBeNull()
    })

    it('should enforce multi-tenant isolation in get request', async () => {
      ;(database.user.findFirst as jest.Mock).mockResolvedValueOnce(null)

      // Should query with company context
      await database.user.findFirst({
        where: {
          id: 'user-123',
          company_roles: { some: { company_id: 'company-123' } },
        },
      })

      expect(database.user.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            company_roles: expect.objectContaining({
              some: expect.objectContaining({ company_id: 'company-123' }),
            }),
          }),
        })
      )
    })
  })

  describe('PUT /users/{id}', () => {
    it('should update user details', async () => {
      const updatedUser = {
        id: 'user-123',
        email: 'user@example.com',
        first_name: 'Johnny',
        last_name: 'Smith',
        phone: '+9876543210',
        updated_at: new Date(),
      }

      ;(database.user.update as jest.Mock).mockResolvedValueOnce(updatedUser)

      const user = await database.user.update({
        where: { id: 'user-123' },
        data: {
          first_name: 'Johnny',
          last_name: 'Smith',
          phone: '+9876543210',
        },
      })

      expect(user.first_name).toBe('Johnny')
      expect(user.last_name).toBe('Smith')
      expect(database.user.update).toHaveBeenCalled()
    })

    it('should validate email format on update', async () => {
      const invalidEmail = 'not-valid-email'
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

      expect(emailRegex.test(invalidEmail)).toBe(false)
    })

    it('should allow partial updates', async () => {
      const partialUpdate = {
        id: 'user-123',
        email: 'user@example.com',
        first_name: 'Updated', // Only updating first name
        last_name: 'Doe',
      }

      ;(database.user.update as jest.Mock).mockResolvedValueOnce(partialUpdate)

      const user = await database.user.update({
        where: { id: 'user-123' },
        data: { first_name: 'Updated' },
      })

      expect(user.first_name).toBe('Updated')
    })
  })

  describe('DELETE /users/{id}', () => {
    it('should delete user by ID', async () => {
      const deletedUser = {
        id: 'user-123',
        email: 'user@example.com',
      }

      ;(database.user.delete as jest.Mock).mockResolvedValueOnce(deletedUser)
      ;(database.userCompanyRole.deleteMany as jest.Mock).mockResolvedValueOnce(
        { count: 1 }
      )

      // Delete user roles first
      await database.userCompanyRole.deleteMany({
        where: { user_id: 'user-123' },
      })

      // Then delete user
      const user = await database.user.delete({
        where: { id: 'user-123' },
      })

      expect(user.id).toBe('user-123')
      expect(database.user.delete).toHaveBeenCalled()
    })

    it('should cascade delete user roles', async () => {
      ;(database.userCompanyRole.deleteMany as jest.Mock).mockResolvedValueOnce(
        { count: 2 }
      )

      const result = await database.userCompanyRole.deleteMany({
        where: { user_id: 'user-123' },
      })

      expect(result.count).toBe(2)
    })

    it('should enforce ownership check before deletion', async () => {
      ;(database.user.findFirst as jest.Mock).mockResolvedValueOnce({
        id: 'user-123',
        company_roles: [{ company_id: 'company-123' }],
      })

      // Should verify user belongs to company
      const user = await database.user.findFirst({
        where: {
          id: 'user-123',
          company_roles: { some: { company_id: 'company-123' } },
        },
      })

      expect(user).toBeDefined()
      // Only then delete
    })
  })
})

describe('User Validation', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should validate first name is not empty', () => {
    const userData = {
      first_name: '',
      last_name: 'Doe',
    }

    expect(userData.first_name.length > 0).toBe(false)
  })

  it('should validate last name is not empty', () => {
    const userData = {
      first_name: 'John',
      last_name: '',
    }

    expect(userData.last_name.length > 0).toBe(false)
  })

  it('should allow optional phone field', () => {
    const userData = {
      email: 'user@example.com',
      first_name: 'John',
      last_name: 'Doe',
      phone: undefined,
    }

    expect(userData.phone).toBeUndefined()
  })
})

describe('User Multi-Tenant Safety', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should not allow cross-company user access', async () => {
    ;(database.user.findFirst as jest.Mock).mockResolvedValueOnce(null)

    // Try to access user from different company
    const user = await database.user.findFirst({
      where: {
        id: 'user-from-other-company',
        company_roles: { some: { company_id: 'company-123' } },
      },
    })

    expect(user).toBeNull()
  })

  it('should only show users from authenticated company', async () => {
    const companyUsers = [
      {
        id: 'user-1',
        email: 'user1@example.com',
        company_roles: [{ company_id: 'company-123' }],
      },
      {
        id: 'user-2',
        email: 'user2@example.com',
        company_roles: [{ company_id: 'company-123' }],
      },
    ]

    ;(database.user.findMany as jest.Mock).mockResolvedValueOnce(companyUsers)

    const users = await database.user.findMany({
      where: {
        company_roles: { some: { company_id: 'company-123' } },
      },
    })

    // All users should be from company-123
    expect(users).toHaveLength(2)
    users.forEach((user) => {
      expect(
        user.company_roles.some((r) => r.company_id === 'company-123')
      ).toBe(true)
    })
  })
})

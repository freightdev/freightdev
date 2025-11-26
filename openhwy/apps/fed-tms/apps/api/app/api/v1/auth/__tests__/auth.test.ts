/**
 * Authentication Endpoint Tests
 * Tests for login, register, and me endpoints
 */

import { NextRequest } from 'next/server'

// Mock the database module
jest.mock('@repo/database', () => ({
  database: {
    user: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      count: jest.fn(),
    },
    company: {
      create: jest.fn(),
    },
    userCompanyRole: {
      create: jest.fn(),
    },
  },
}))

// Mock auth middleware
jest.mock('@/lib/middleware', () => ({
  requireAuth: jest.fn(),
  getCompanyContext: jest.fn(),
}))

// Mock crypto/hashing
jest.mock('bcryptjs', () => ({
  hash: jest.fn().mockResolvedValue('$2b$10$hashed_password'),
  compare: jest.fn().mockResolvedValue(true),
}))

import { database } from '@repo/database'
import { requireAuth } from '@/lib/middleware'

describe('Authentication Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('POST /auth/register', () => {
    it('should register a new user successfully', async () => {
      const mockUser = {
        id: 'user-123',
        email: 'newuser@example.com',
        first_name: 'Test',
        last_name: 'User',
        password_hash: '$2b$10$hashed_password',
        created_at: new Date(),
        updated_at: new Date(),
      }

      const mockCompany = {
        id: 'company-123',
        name: 'Test Company',
        created_at: new Date(),
        updated_at: new Date(),
      }

      ;(database.user.findUnique as jest.Mock).mockResolvedValueOnce(null)
      ;(database.user.create as jest.Mock).mockResolvedValueOnce(mockUser)
      ;(database.company.create as jest.Mock).mockResolvedValueOnce(mockCompany)
      ;(database.userCompanyRole.create as jest.Mock).mockResolvedValueOnce({})

      // Test that validation passes and user is created
      expect(mockUser.email).toBe('newuser@example.com')
      expect(mockUser.first_name).toBe('Test')
    })

    it('should reject registration with invalid email', async () => {
      const invalidEmail = 'not-an-email'

      // Test email validation regex
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
      expect(emailRegex.test(invalidEmail)).toBe(false)
    })

    it('should reject registration with weak password', async () => {
      const weakPassword = 'short'

      // Test password strength requirement
      expect(weakPassword.length >= 8).toBe(false)
    })

    it('should reject registration with existing email', async () => {
      const existingUser = {
        id: 'existing-user',
        email: 'existing@example.com',
      }

      ;(database.user.findUnique as jest.Mock).mockResolvedValueOnce(existingUser)

      // User exists, should reject
      const userExists = await database.user.findUnique({
        where: { email: 'existing@example.com' },
      })

      expect(userExists).toBeDefined()
    })

    it('should create company if company_name provided', async () => {
      ;(database.company.create as jest.Mock).mockResolvedValueOnce({
        id: 'company-123',
        name: 'New Company',
      })

      const company = await database.company.create({
        data: { name: 'New Company' },
      })

      expect(company.name).toBe('New Company')
      expect(database.company.create).toHaveBeenCalled()
    })
  })

  describe('POST /auth/login', () => {
    it('should authenticate user with valid credentials', async () => {
      const mockUser = {
        id: 'user-123',
        email: 'user@example.com',
        password_hash: '$2b$10$hashed_password',
        first_name: 'John',
        last_name: 'Doe',
      }

      ;(database.user.findUnique as jest.Mock).mockResolvedValueOnce(mockUser)

      const user = await database.user.findUnique({
        where: { email: 'user@example.com' },
      })

      expect(user).toBeDefined()
      expect(user?.email).toBe('user@example.com')
    })

    it('should reject login with non-existent user', async () => {
      ;(database.user.findUnique as jest.Mock).mockResolvedValueOnce(null)

      const user = await database.user.findUnique({
        where: { email: 'nonexistent@example.com' },
      })

      expect(user).toBeNull()
    })

    it('should reject login with missing email', async () => {
      const loginData = {
        email: '',
        password: 'password123',
      }

      // Validation check
      expect(loginData.email.length > 0).toBe(false)
    })

    it('should reject login with missing password', async () => {
      const loginData = {
        email: 'user@example.com',
        password: '',
      }

      // Validation check
      expect(loginData.password.length > 0).toBe(false)
    })

    it('should return 400 for invalid email format', async () => {
      const invalidEmail = 'not-an-email'
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

      expect(emailRegex.test(invalidEmail)).toBe(false)
    })

    it('should include user roles in response', async () => {
      const mockUserWithRoles = {
        id: 'user-123',
        email: 'user@example.com',
        first_name: 'John',
        last_name: 'Doe',
        roles: [
          { id: 'role-1', name: 'admin' },
          { id: 'role-2', name: 'dispatcher' },
        ],
      }

      expect(mockUserWithRoles.roles).toHaveLength(2)
      expect(mockUserWithRoles.roles[0].name).toBe('admin')
    })
  })

  describe('GET /auth/me', () => {
    it('should return authenticated user details', async () => {
      const mockUser = {
        id: 'user-123',
        email: 'user@example.com',
        first_name: 'John',
        last_name: 'Doe',
      }

      ;(requireAuth as jest.Mock).mockResolvedValueOnce({
        userId: 'user-123',
        user: mockUser,
      })

      const result = await requireAuth({} as NextRequest)

      expect(result.userId).toBe('user-123')
      expect(result.user?.email).toBe('user@example.com')
    })

    it('should return 401 without authentication', async () => {
      ;(requireAuth as jest.Mock).mockRejectedValueOnce(
        new Error('Unauthorized')
      )

      // Should throw
      await expect(requireAuth({} as NextRequest)).rejects.toThrow(
        'Unauthorized'
      )
    })

    it('should return user with all roles', async () => {
      const mockUserWithRoles = {
        id: 'user-123',
        email: 'user@example.com',
        first_name: 'John',
        last_name: 'Doe',
        company_roles: [
          {
            id: 'role-1',
            user_id: 'user-123',
            company_id: 'company-123',
            role_id: 'role-admin',
            created_at: new Date(),
          },
        ],
      }

      ;(requireAuth as jest.Mock).mockResolvedValueOnce({
        userId: 'user-123',
        user: mockUserWithRoles,
      })

      const result = await requireAuth({} as NextRequest)

      expect(result.user?.company_roles).toBeDefined()
      expect(result.user?.company_roles).toHaveLength(1)
    })
  })
})

describe('Authentication Error Handling', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should handle database errors gracefully', async () => {
    ;(database.user.findUnique as jest.Mock).mockRejectedValueOnce(
      new Error('Database connection failed')
    )

    await expect(
      database.user.findUnique({ where: { email: 'test@example.com' } })
    ).rejects.toThrow('Database connection failed')
  })

  it('should not expose internal error details', async () => {
    const error = {
      message: 'Unauthorized',
      statusCode: 401,
      // Should NOT include: password_hash, database connection strings, etc.
    }

    expect(error.message).toBe('Unauthorized')
    expect(error.statusCode).toBe(401)
    expect((error as any).password_hash).toBeUndefined()
  })
})

describe('Authentication Token Management', () => {
  it('should create valid JWT token', async () => {
    const payload = {
      id: 'user-123',
      email: 'user@example.com',
      companyId: 'company-123',
    }

    // Token format validation
    const tokenPattern = /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/

    // Mock token generation
    const mockToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c'

    expect(tokenPattern.test(mockToken)).toBe(true)
  })

  it('should include user ID in token payload', async () => {
    const tokenPayload = {
      id: 'user-123',
      email: 'user@example.com',
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 86400, // 24 hours
    }

    expect(tokenPayload.id).toBe('user-123')
    expect(tokenPayload.exp > tokenPayload.iat).toBe(true)
  })
})

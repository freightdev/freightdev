// Jest setup file for test configuration
import 'dotenv/config'

// Set test environment
process.env.NODE_ENV = 'test'
process.env.JWT_SECRET = 'test-secret-key-for-jest'
process.env.JWT_EXPIRY = '24h'

// Suppress console logs during tests (optional)
global.console = {
  ...console,
  error: jest.fn(),
  warn: jest.fn(),
}

// Mock Next.js router
jest.mock('next/router', () => ({
  useRouter: () => ({
    push: jest.fn(),
    pathname: '/',
    query: {},
    asPath: '/',
  }),
}))

// Mock Next.js navigation
jest.mock('next/navigation', () => ({
  useRouter: () => ({
    push: jest.fn(),
    pathname: '/',
    query: {},
    asPath: '/',
  }),
  usePathname: () => '/',
}))

// Set reasonable timeouts
jest.setTimeout(10000)

// Clean up after each test
afterEach(() => {
  jest.clearAllMocks()
})

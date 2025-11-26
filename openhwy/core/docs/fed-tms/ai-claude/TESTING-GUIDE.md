# FED-TMS API Testing Guide

Complete guide for testing the FED-TMS API endpoints with Jest, integration tests, and manual testing.

## Testing Setup

### Prerequisites

```bash
npm install --save-dev jest @types/jest ts-jest
npm install --save-dev @testing-library/react @testing-library/jest-dom
npm install --save-dev supertest @types/supertest
npm install --save-dev dotenv
```

### Jest Configuration

Create `jest.config.js` in `apps/api`:

```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  moduleFileExtensions: ['ts', 'js', 'json'],
  collectCoverageFrom: [
    'app/**/*.ts',
    'lib/**/*.ts',
    '!**/*.d.ts',
    '!**/node_modules/**',
  ],
  coveragePathIgnorePatterns: ['/node_modules/'],
}
```

### Test Environment Setup

Create `.env.test`:

```
DATABASE_URL=postgresql://fedtms:fedtms_dev_password@localhost:5432/fedtms_test
JWT_SECRET=test-secret-key-change-in-production
JWT_EXPIRY=24h
NODE_ENV=test
```

## Unit Tests

### Authentication Tests

Create `app/api/v1/auth/__tests__/login.test.ts`:

```typescript
import { POST as loginHandler } from '../login/route'
import { NextRequest } from 'next/server'
import { database } from '@repo/database'

// Mock database
jest.mock('@repo/database', () => ({
  database: {
    user: {
      findUnique: jest.fn(),
    },
  },
}))

describe('POST /auth/login', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should authenticate user with valid credentials', async () => {
    const mockUser = {
      id: 'user-123',
      email: 'test@example.com',
      password_hash: '$2b$10$...', // hashed password
      first_name: 'Test',
      last_name: 'User',
    }

    ;(database.user.findUnique as jest.Mock).mockResolvedValue(mockUser)

    const request = new NextRequest(new URL('http://localhost:3002/api/v1/auth/login'), {
      method: 'POST',
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'password123',
      }),
    })

    const response = await loginHandler(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.success).toBe(true)
    expect(data.data.token).toBeDefined()
  })

  it('should return 400 for invalid email', async () => {
    const request = new NextRequest(new URL('http://localhost:3002/api/v1/auth/login'), {
      method: 'POST',
      body: JSON.stringify({
        email: 'not-an-email',
        password: 'password123',
      }),
    })

    const response = await loginHandler(request)
    expect(response.status).toBe(400)
  })

  it('should return 400 for wrong password', async () => {
    ;(database.user.findUnique as jest.Mock).mockResolvedValue(null)

    const request = new NextRequest(new URL('http://localhost:3002/api/v1/auth/login'), {
      method: 'POST',
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'wrongpassword',
      }),
    })

    const response = await loginHandler(request)
    expect(response.status).toBe(400)
  })
})
```

### Driver Endpoint Tests

Create `app/api/v1/drivers/__tests__/drivers.test.ts`:

```typescript
import { GET as listDrivers, POST as createDriver } from '../route'
import { NextRequest } from 'next/server'
import { database } from '@repo/database'

jest.mock('@repo/database')
jest.mock('@/lib/middleware', () => ({
  requireAuth: jest.fn(() => Promise.resolve({ userId: 'user-123' })),
  getCompanyContext: jest.fn(() => Promise.resolve({ companyId: 'company-123' })),
  getQueryParams: jest.fn(() => ({
    page: 1,
    limit: 10,
    skip: 0,
  })),
}))

describe('Drivers Endpoints', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('GET /drivers', () => {
    it('should list drivers with pagination', async () => {
      const mockDrivers = [
        {
          id: 'driver-123',
          user_id: 'user-123',
          license_number: 'DL123',
          company_id: 'company-123',
          status: 'active',
        },
      ]

      ;(database.driver.findMany as jest.Mock).mockResolvedValue(mockDrivers)
      ;(database.driver.count as jest.Mock).mockResolvedValue(1)

      const request = new NextRequest(new URL('http://localhost:3002/api/v1/drivers'), {
        method: 'GET',
      })

      const response = await listDrivers(request)
      const data = await response.json()

      expect(response.status).toBe(200)
      expect(data.success).toBe(true)
      expect(data.data).toHaveLength(1)
      expect(data.pagination).toBeDefined()
    })
  })

  describe('POST /drivers', () => {
    it('should create new driver', async () => {
      const mockDriver = {
        id: 'driver-123',
        user_id: 'user-123',
        license_number: 'DL123',
        company_id: 'company-123',
        status: 'active',
      }

      ;(database.driver.create as jest.Mock).mockResolvedValue(mockDriver)
      ;(database.user.findFirst as jest.Mock).mockResolvedValue({ id: 'user-123' })

      const request = new NextRequest(new URL('http://localhost:3002/api/v1/drivers'), {
        method: 'POST',
        body: JSON.stringify({
          user_id: 'user-123',
          license_number: 'DL123',
          vehicle_type: 'truck',
        }),
      })

      const response = await createDriver(request)
      const data = await response.json()

      expect(response.status).toBe(201)
      expect(data.success).toBe(true)
      expect(data.data.id).toBe('driver-123')
    })

    it('should validate required fields', async () => {
      const request = new NextRequest(new URL('http://localhost:3002/api/v1/drivers'), {
        method: 'POST',
        body: JSON.stringify({
          // Missing user_id and license_number
          vehicle_type: 'truck',
        }),
      })

      const response = await createDriver(request)
      expect(response.status).toBe(400)
    })
  })
})
```

## Integration Tests

### End-to-End Driver Flow

Create `__tests__/integration/driver-flow.test.ts`:

```typescript
import { database } from '@repo/database'
import request from 'supertest'

const BASE_URL = 'http://localhost:3002/api/v1'
let authToken: string
let driverId: string
let companyId: string

describe('Driver Management Flow', () => {
  beforeAll(async () => {
    // Clean up test data
    await database.driver.deleteMany({})
    await database.user.deleteMany({})
    await database.company.deleteMany({})
  })

  afterAll(async () => {
    // Clean up
    await database.driver.deleteMany({})
    await database.user.deleteMany({})
    await database.company.deleteMany({})
  })

  it('should complete driver lifecycle', async () => {
    // Step 1: Register company and user
    const registerRes = await request(BASE_URL)
      .post('/auth/register')
      .send({
        email: 'dispatcher@test.com',
        password: 'Password123!',
        first_name: 'Test',
        last_name: 'Dispatcher',
        company_name: 'Test Dispatch Co',
      })

    expect(registerRes.status).toBe(201)
    authToken = registerRes.body.data.token
    companyId = registerRes.body.data.user.company_id

    // Step 2: Create a driver
    const driverRes = await request(BASE_URL)
      .post('/drivers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        user_id: registerRes.body.data.user.id,
        license_number: 'DL123456',
        license_class: 'A',
        vehicle_type: 'tractor-trailer',
        vehicle_vin: 'VIN123456',
        vehicle_plate: 'ABC123',
      })

    expect(driverRes.status).toBe(201)
    driverId = driverRes.body.data.id
    expect(driverRes.body.data.status).toBe('active')

    // Step 3: Get driver details
    const getRes = await request(BASE_URL)
      .get(`/drivers/${driverId}`)
      .set('Authorization', `Bearer ${authToken}`)

    expect(getRes.status).toBe(200)
    expect(getRes.body.data.id).toBe(driverId)

    // Step 4: Update driver
    const updateRes = await request(BASE_URL)
      .put(`/drivers/${driverId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        vehicle_type: 'straight-truck',
        status: 'active',
      })

    expect(updateRes.status).toBe(200)
    expect(updateRes.body.data.vehicle_type).toBe('straight-truck')

    // Step 5: Upload driver document
    const docRes = await request(BASE_URL)
      .post(`/drivers/${driverId}/documents`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        type: 'license',
        document_url: 'https://example.com/license.pdf',
        expiry_date: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString(),
      })

    expect(docRes.status).toBe(201)
    expect(docRes.body.data.type).toBe('license')

    // Step 6: Get driver location
    const locRes = await request(BASE_URL)
      .post(`/drivers/${driverId}/locations`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        latitude: 40.7128,
        longitude: -74.006,
        accuracy: 10,
      })

    expect(locRes.status).toBe(201)

    // Step 7: Add driver rating
    const ratingRes = await request(BASE_URL)
      .post(`/drivers/${driverId}/ratings`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        rating: 5,
        comment: 'Excellent driver',
      })

    expect(ratingRes.status).toBe(201)

    // Step 8: Get driver ratings
    const ratingsRes = await request(BASE_URL)
      .get(`/drivers/${driverId}/ratings`)
      .set('Authorization', `Bearer ${authToken}`)

    expect(ratingsRes.status).toBe(200)
    expect(ratingsRes.body.data.ratings).toHaveLength(1)
    expect(ratingsRes.body.data.average).toBe(5)
  })
})
```

### Load Assignment Flow

Create `__tests__/integration/load-flow.test.ts`:

```typescript
import request from 'supertest'

const BASE_URL = 'http://localhost:3002/api/v1'
let authToken: string
let driverId: string
let loadId: string

describe('Load Management Flow', () => {
  beforeAll(async () => {
    // Register user and create driver
    const registerRes = await request(BASE_URL)
      .post('/auth/register')
      .send({
        email: 'dispatcher@test.com',
        password: 'Password123!',
        first_name: 'Test',
        last_name: 'Dispatcher',
        company_name: 'Test Company',
      })

    authToken = registerRes.body.data.token

    const driverRes = await request(BASE_URL)
      .post('/drivers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        user_id: registerRes.body.data.user.id,
        license_number: 'DL123',
        vehicle_type: 'truck',
      })

    driverId = driverRes.body.data.id
  })

  it('should complete load lifecycle with tracking', async () => {
    // Step 1: Create load
    const createRes = await request(BASE_URL)
      .post('/loads')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        reference_number: 'LOAD-001',
        pickup_address: '123 Main St',
        pickup_city: 'New York',
        pickup_state: 'NY',
        pickup_zip: '10001',
        pickup_date: new Date().toISOString(),
        delivery_address: '456 Oak Ave',
        delivery_city: 'Boston',
        delivery_state: 'MA',
        delivery_zip: '02101',
        delivery_date: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        rate: 1500,
        commodity: 'Electronics',
        weight: 5000,
      })

    expect(createRes.status).toBe(201)
    loadId = createRes.body.data.id
    expect(createRes.body.data.status).toBe('pending')

    // Step 2: Assign driver
    const assignRes = await request(BASE_URL)
      .post(`/loads/${loadId}/assignments`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        driver_id: driverId,
      })

    expect(assignRes.status).toBe(201)

    // Step 3: Update tracking
    const trackingRes = await request(BASE_URL)
      .post(`/loads/${loadId}/tracking`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        status: 'pickup_completed',
        latitude: 40.7128,
        longitude: -74.006,
      })

    expect(trackingRes.status).toBe(201)

    // Step 4: Verify load status updated
    const getRes = await request(BASE_URL)
      .get(`/loads/${loadId}`)
      .set('Authorization', `Bearer ${authToken}`)

    expect(getRes.status).toBe(200)

    // Step 5: Update to in transit
    const transitRes = await request(BASE_URL)
      .post(`/loads/${loadId}/tracking`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        status: 'in_transit',
        latitude: 40.8,
        longitude: -74.1,
      })

    expect(transitRes.status).toBe(201)

    // Step 6: Mark as delivered
    const deliveredRes = await request(BASE_URL)
      .post(`/loads/${loadId}/tracking`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        status: 'delivered',
        latitude: 42.3601,
        longitude: -71.0589,
      })

    expect(deliveredRes.status).toBe(201)

    // Step 7: Verify final status
    const finalRes = await request(BASE_URL)
      .get(`/loads/${loadId}`)
      .set('Authorization', `Bearer ${authToken}`)

    expect(finalRes.body.data.status).toBe('delivered')
  })
})
```

### Invoice and Payment Flow

Create `__tests__/integration/payment-flow.test.ts`:

```typescript
import request from 'supertest'

const BASE_URL = 'http://localhost:3002/api/v1'
let authToken: string
let invoiceId: string
let paymentId: string

describe('Invoice and Payment Flow', () => {
  beforeAll(async () => {
    const registerRes = await request(BASE_URL)
      .post('/auth/register')
      .send({
        email: 'accounting@test.com',
        password: 'Password123!',
        first_name: 'Accounting',
        last_name: 'Manager',
        company_name: 'Test Company',
      })

    authToken = registerRes.body.data.token
  })

  it('should handle invoice and payment workflow', async () => {
    // Step 1: Create invoice
    const invoiceRes = await request(BASE_URL)
      .post('/invoices')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        invoice_number: 'INV-001',
        amount: 1500,
        due_date: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        description: 'Freight charges for load',
      })

    expect(invoiceRes.status).toBe(201)
    invoiceId = invoiceRes.body.data.id
    expect(invoiceRes.body.data.status).toBe('pending')

    // Step 2: Get invoice with totals
    const getRes = await request(BASE_URL)
      .get(`/invoices/${invoiceId}`)
      .set('Authorization', `Bearer ${authToken}`)

    expect(getRes.status).toBe(200)
    expect(getRes.body.data.totalPaid).toBe(0)
    expect(getRes.body.data.remaining).toBe(1500)

    // Step 3: Create payment
    const paymentRes = await request(BASE_URL)
      .post('/payments')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        invoice_id: invoiceId,
        amount: 750,
        method: 'card',
        transaction_id: 'txn-001',
      })

    expect(paymentRes.status).toBe(201)
    paymentId = paymentRes.body.data.id
    expect(paymentRes.body.data.status).toBe('pending')

    // Step 4: Get payment
    const getPaymentRes = await request(BASE_URL)
      .get(`/payments/${paymentId}`)
      .set('Authorization', `Bearer ${authToken}`)

    expect(getPaymentRes.status).toBe(200)

    // Step 5: Mark payment as completed
    const updatePaymentRes = await request(BASE_URL)
      .put(`/payments/${paymentId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        status: 'completed',
      })

    expect(updatePaymentRes.status).toBe(200)

    // Step 6: Create second payment
    const payment2Res = await request(BASE_URL)
      .post('/payments')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        invoice_id: invoiceId,
        amount: 750,
        method: 'ach',
      })

    expect(payment2Res.status).toBe(201)

    // Step 7: Verify invoice totals
    const finalRes = await request(BASE_URL)
      .get(`/invoices/${invoiceId}`)
      .set('Authorization', `Bearer ${authToken}`)

    expect(finalRes.body.data.totalPaid).toBe(750) // Only first completed payment
  })
})
```

## Manual Testing Checklist

### Authentication Tests
- [ ] Register new user with valid data
- [ ] Register with existing email (should fail)
- [ ] Register with weak password (should fail)
- [ ] Login with correct credentials
- [ ] Login with wrong password
- [ ] Access protected endpoint without token
- [ ] Access protected endpoint with invalid token
- [ ] Token expiration (wait 24h or mock time)

### Multi-Tenant Tests
- [ ] User 1 creates resource
- [ ] User 1 can view their resource
- [ ] User 2 cannot view User 1's resource
- [ ] User 2 creates their own resource
- [ ] Users' resources are completely isolated

### Data Validation Tests
- [ ] Required fields validation
- [ ] Email format validation
- [ ] Number ranges (ratings 1-5)
- [ ] Date format validation
- [ ] Coordinates range (-90 to 90 latitude, -180 to 180 longitude)

### Pagination Tests
- [ ] Default page and limit
- [ ] Custom page/limit values
- [ ] Large limit value
- [ ] Page beyond available data
- [ ] Total count accuracy

### Error Handling Tests
- [ ] Malformed JSON request
- [ ] Wrong HTTP method
- [ ] Invalid path
- [ ] Resource not found (404)
- [ ] Unauthorized (401)
- [ ] Forbidden (403)

### Business Logic Tests
- [ ] Driver rating updates average correctly
- [ ] Load status changes with tracking updates
- [ ] Payment amount validation against invoice
- [ ] Invoice total calculations
- [ ] Notification creation and reading

### Performance Tests
- [ ] List endpoint with 1000+ items
- [ ] Search performance
- [ ] Pagination performance
- [ ] Concurrent requests
- [ ] Response time under load

## Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- auth.test.ts

# Run with coverage
npm test -- --coverage

# Run integration tests only
npm test -- integration

# Watch mode
npm test -- --watch
```

## Coverage Goals

- **Statements**: 80%+
- **Branches**: 75%+
- **Functions**: 80%+
- **Lines**: 80%+

## Test Report

After running tests, view coverage:

```bash
npm test -- --coverage
open coverage/lcov-report/index.html
```

## Continuous Integration

Add to GitHub Actions `.github/workflows/test.yml`:

```yaml
name: API Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: fedtms_test
          POSTGRES_PASSWORD: password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3

      - uses: actions/setup-node@v3
        with:
          node-version: '20'

      - run: npm ci

      - run: npm test -- --coverage

      - uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
```

## Next Steps

1. Implement all unit tests for endpoints
2. Expand integration test coverage
3. Add performance benchmarks
4. Set up CI/CD pipeline
5. Monitor test coverage metrics
6. Create test data factory functions

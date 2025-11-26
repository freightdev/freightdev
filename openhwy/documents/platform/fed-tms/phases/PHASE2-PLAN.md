# 📋 PHASE 2 PLAN: API Implementation
## FED-TMS - REST API Endpoints

**Phase 1 Status:** ✅ COMPLETE
**Phase 2 Status:** 🟡 READY TO START
**Estimated Duration:** 1 week
**Target Completion:** 2025-12-02

---

## Phase 2 Overview

Build comprehensive REST API endpoints for all TMS operations. Phase 1 laid the foundation; Phase 2 will create the functional API layer that the frontend and mobile apps will consume.

---

## Architecture: API Layer Design

```
Requests
    ↓
Next.js App Router (/apps/api/app)
    ↓
Route Handlers (/api/v1/*)
    ↓
Request Validation (Zod schemas)
    ↓
Business Logic (Service layer)
    ↓
Database Queries (Prisma Client)
    ↓
Response Formatting & Error Handling
    ↓
JSON Response
```

---

## Phase 2 Tasks (Proposed)

### TASK 1: Core API Infrastructure
**Scope:** Setup route handlers, middleware, error handling
**Files to Create:**
- `apps/api/app/api/v1/` - API routes directory
- `apps/api/lib/api-utils.ts` - Response formatting
- `apps/api/lib/error-handler.ts` - Error handling
- `apps/api/lib/validators.ts` - Zod schemas
- `apps/api/middleware.ts` - Auth/logging middleware

**Endpoints:** (0 functional)
**Estimate:** 2 hours

---

### TASK 2: Authentication Endpoints
**Scope:** Login, register, token refresh, logout
**Endpoints:** (4 endpoints)
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Token refresh
- `POST /api/v1/auth/logout` - Logout

**Estimate:** 3 hours

---

### TASK 3: User Management Endpoints
**Scope:** User CRUD and profile management
**Endpoints:** (8 endpoints)
- `GET /api/v1/users` - List users (admin)
- `GET /api/v1/users/:id` - Get user details
- `POST /api/v1/users` - Create user (admin)
- `PUT /api/v1/users/:id` - Update user
- `DELETE /api/v1/users/:id` - Delete user
- `GET /api/v1/users/me` - Get current user
- `PUT /api/v1/users/me/profile` - Update profile
- `PUT /api/v1/users/me/password` - Change password

**Estimate:** 4 hours

---

### TASK 4: Driver Management Endpoints
**Scope:** Driver CRUD, documents, locations, ratings
**Endpoints:** (12 endpoints)
- `GET /api/v1/drivers` - List drivers
- `POST /api/v1/drivers` - Create driver
- `GET /api/v1/drivers/:id` - Get driver
- `PUT /api/v1/drivers/:id` - Update driver
- `DELETE /api/v1/drivers/:id` - Delete driver
- `GET /api/v1/drivers/:id/documents` - Driver documents
- `POST /api/v1/drivers/:id/documents` - Upload document
- `DELETE /api/v1/drivers/:id/documents/:docId` - Delete document
- `GET /api/v1/drivers/:id/locations` - Location history
- `POST /api/v1/drivers/:id/locations` - Update location
- `GET /api/v1/drivers/:id/ratings` - Driver ratings
- `POST /api/v1/drivers/:id/ratings` - Add rating

**Estimate:** 5 hours

---

### TASK 5: Load Management Endpoints
**Scope:** Load CRUD, assignments, tracking, documents
**Endpoints:** (14 endpoints)
- `GET /api/v1/loads` - List loads
- `POST /api/v1/loads` - Create load
- `GET /api/v1/loads/:id` - Get load details
- `PUT /api/v1/loads/:id` - Update load
- `DELETE /api/v1/loads/:id` - Delete load
- `GET /api/v1/loads/:id/assignments` - Load assignments
- `POST /api/v1/loads/:id/assignments` - Assign driver
- `PUT /api/v1/loads/:id/assignments/:assignId` - Update assignment
- `DELETE /api/v1/loads/:id/assignments/:assignId` - Remove assignment
- `GET /api/v1/loads/:id/tracking` - Load tracking
- `POST /api/v1/loads/:id/tracking` - Update tracking
- `GET /api/v1/loads/:id/documents` - Load documents
- `POST /api/v1/loads/:id/documents` - Upload document
- `DELETE /api/v1/loads/:id/documents/:docId` - Delete document

**Estimate:** 6 hours

---

### TASK 6: Payment & Invoice Endpoints
**Scope:** Invoice CRUD, payments, payment methods
**Endpoints:** (12 endpoints)
- `GET /api/v1/invoices` - List invoices
- `POST /api/v1/invoices` - Create invoice
- `GET /api/v1/invoices/:id` - Get invoice
- `PUT /api/v1/invoices/:id` - Update invoice
- `DELETE /api/v1/invoices/:id` - Delete invoice
- `GET /api/v1/payments` - List payments
- `POST /api/v1/payments` - Create payment
- `GET /api/v1/payments/:id` - Get payment
- `PUT /api/v1/payments/:id` - Update payment status
- `GET /api/v1/payment-methods` - List payment methods
- `POST /api/v1/payment-methods` - Add payment method
- `DELETE /api/v1/payment-methods/:id` - Delete payment method

**Estimate:** 5 hours

---

### TASK 7: Communication Endpoints
**Scope:** Messages, conversations, notifications
**Endpoints:** (10 endpoints)
- `GET /api/v1/conversations` - List conversations
- `POST /api/v1/conversations` - Create conversation
- `GET /api/v1/conversations/:id` - Get conversation
- `GET /api/v1/conversations/:id/messages` - Get messages
- `POST /api/v1/conversations/:id/messages` - Send message
- `PUT /api/v1/messages/:id` - Edit message
- `DELETE /api/v1/messages/:id` - Delete message
- `GET /api/v1/notifications` - List notifications
- `PUT /api/v1/notifications/:id` - Mark as read
- `DELETE /api/v1/notifications/:id` - Delete notification

**Estimate:** 4 hours

---

### TASK 8: Search & Filtering
**Scope:** Advanced filtering and search capabilities
**Features:**
- Full-text search on drivers, loads, users
- Date range filtering
- Status filtering
- Sorting and pagination
- Advanced query parameters

**Estimate:** 3 hours

---

### TASK 9: Testing & Documentation
**Scope:** Unit tests, integration tests, API docs
**Files to Create:**
- `apps/api/__tests__/` - Test suite
- `apps/api/docs/API.md` - API documentation
- Postman collection (optional)

**Estimate:** 4 hours

---

## Phase 2 Summary

**Total Endpoints:** ~70 REST endpoints
**Total Time:** ~36 hours (~1 week)
**Files to Create:** ~15 new files
**Test Coverage:** Target 80%+
**Documentation:** Complete API spec with examples

---

## Implementation Strategy

### Week 1: Core APIs
- Day 1: Task 1 (Infrastructure) + Task 2 (Auth)
- Day 2: Task 3 (Users) + Task 4 (Drivers part 1)
- Day 3: Task 4 (Drivers part 2) + Task 5 (Loads part 1)
- Day 4: Task 5 (Loads part 2) + Task 6 (Payments)
- Day 5: Task 7 (Communications) + Task 8 (Search)
- Day 6: Task 9 (Testing & Docs)
- Day 7: Review, polish, final testing

---

## Code Patterns

### Route Handler Pattern
```typescript
// apps/api/app/api/v1/users/route.ts
import { auth } from '@repo/auth'
import { database } from '@repo/database'
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const user = await auth()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  try {
    const users = await database.user.findMany()
    return NextResponse.json(users)
  } catch (error) {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 })
  }
}
```

### Validation Pattern
```typescript
// apps/api/lib/validators.ts
import { z } from 'zod'

export const CreateUserSchema = z.object({
  email: z.string().email(),
  first_name: z.string().min(1),
  last_name: z.string().min(1),
  password: z.string().min(8),
})

export type CreateUserInput = z.infer<typeof CreateUserSchema>
```

### Error Handling Pattern
```typescript
try {
  const result = await someOperation()
  return NextResponse.json(result)
} catch (error) {
  console.error('Error:', error)
  return NextResponse.json(
    { error: error instanceof Error ? error.message : 'Unknown error' },
    { status: 500 }
  )
}
```

---

## Success Criteria

- ✅ All 70+ endpoints implemented
- ✅ Request validation with Zod
- ✅ Proper error handling
- ✅ 80%+ test coverage
- ✅ Complete API documentation
- ✅ CORS properly configured
- ✅ Rate limiting in place (optional)
- ✅ Logging implemented
- ✅ Type-safe throughout

---

## What Comes After Phase 2

**Phase 3:** Frontend Dashboard Implementation
**Phase 4:** Driver Mobile Portal
**Phase 5:** Real-time Features
**Phase 6+:** Advanced features, analytics, etc.

---

## Ready to Proceed?

Phase 2 is ready to start. All infrastructure from Phase 1 is in place.

**Questions for confirmation:**
1. Should I start with Task 1 (Infrastructure setup)?
2. Proceed with all tasks sequentially?
3. Any specific endpoints to prioritize?

Ready when you are!

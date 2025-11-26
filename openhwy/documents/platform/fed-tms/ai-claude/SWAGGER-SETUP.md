# Swagger UI Setup for FED-TMS API

This guide explains how to set up and use Swagger UI to test the FED-TMS API.

## Quick Start

### Option 1: Online Swagger Editor

1. Go to https://editor.swagger.io
2. Copy the contents of `apps/api/openapi.yaml` and paste into the editor
3. Test endpoints directly from the interface

### Option 2: Local Swagger UI Integration

Install swagger-ui-express in your API package:

```bash
cd apps/api
npm install swagger-ui-express
npm install -D @types/swagger-ui-express
```

Update your main API file (`apps/api/app/layout.tsx` or main app file):

```typescript
import swaggerUi from 'swagger-ui-express'
import fs from 'fs'
import YAML from 'yaml'

// Load OpenAPI spec
const openApiSpec = YAML.parse(fs.readFileSync('openapi.yaml', 'utf8'))

// Middleware to serve Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(openApiSpec))
```

Then access the documentation at: `http://localhost:3002/api-docs`

### Option 3: Docker with Swagger UI Container

Create a docker compose service:

```yaml
swagger-ui:
  image: swaggerapi/swagger-ui
  ports:
    - "8080:8080"
  environment:
    - SWAGGER_JSON=/api/openapi.yaml
  volumes:
    - ./apps/api/openapi.yaml:/api/openapi.yaml:ro
  depends_on:
    - api
```

Access at: `http://localhost:8080`

## API Documentation Structure

The OpenAPI spec (`apps/api/openapi.yaml`) includes:

### Components (Reusable Schemas)
- **Common**: Error, Pagination
- **Auth**: LoginRequest, RegisterRequest, AuthResponse
- **Users**: User, UserWithRoles
- **Drivers**: Driver, DriverDocument, DriverLocation, DriverRating
- **Loads**: Load, LoadAssignment, LoadTracking, LoadDocument
- **Invoices**: Invoice, InvoiceLineItem
- **Payments**: Payment, PaymentMethod
- **Notifications**: Notification
- **Conversations**: Conversation, Message

### Paths (25 API Endpoints)

#### Authentication (3)
- `POST /auth/login` - Authenticate user
- `POST /auth/register` - Register new user
- `GET /auth/me` - Get current user

#### Users (5)
- `GET /users` - List users
- `POST /users` - Create user
- `GET /users/{id}` - Get user
- `PUT /users/{id}` - Update user
- `DELETE /users/{id}` - Delete user

#### Drivers (14)
- `GET /drivers` - List drivers
- `POST /drivers` - Create driver
- `GET /drivers/{id}` - Get driver
- `PUT /drivers/{id}` - Update driver
- `DELETE /drivers/{id}` - Delete driver
- `GET /drivers/{id}/documents` - List documents
- `POST /drivers/{id}/documents` - Upload document
- `GET /drivers/{id}/documents/{docId}` - Get document
- `PUT /drivers/{id}/documents/{docId}` - Update document
- `DELETE /drivers/{id}/documents/{docId}` - Delete document
- `GET /drivers/{id}/locations` - Location history
- `POST /drivers/{id}/locations` - Update location
- `GET /drivers/{id}/ratings` - Get ratings
- `POST /drivers/{id}/ratings` - Add rating

#### Loads (11)
- `GET /loads` - List loads
- `POST /loads` - Create load
- `GET /loads/{id}` - Get load
- `PUT /loads/{id}` - Update load
- `DELETE /loads/{id}` - Delete load
- `GET /loads/{id}/assignments` - List assignments
- `POST /loads/{id}/assignments` - Assign driver
- `GET /loads/{id}/tracking` - Tracking history
- `POST /loads/{id}/tracking` - Update tracking
- `GET /loads/{id}/documents` - List documents
- `POST /loads/{id}/documents` - Upload document

#### Invoices (5)
- `GET /invoices` - List invoices
- `POST /invoices` - Create invoice
- `GET /invoices/{id}` - Get invoice
- `PUT /invoices/{id}` - Update invoice
- `DELETE /invoices/{id}` - Delete invoice

#### Payments (5)
- `GET /payments` - List payments
- `POST /payments` - Create payment
- `GET /payments/{id}` - Get payment
- `PUT /payments/{id}` - Update payment
- `DELETE /payments/{id}` - Delete payment

#### Notifications (5)
- `GET /notifications` - List notifications
- `POST /notifications` - Create notification
- `GET /notifications/{id}` - Get notification
- `PUT /notifications/{id}` - Update notification
- `DELETE /notifications/{id}` - Delete notification

#### Conversations (7)
- `GET /conversations` - List conversations
- `POST /conversations` - Create conversation
- `GET /conversations/{id}` - Get conversation
- `PUT /conversations/{id}` - Update conversation
- `DELETE /conversations/{id}` - Delete conversation
- `GET /conversations/{id}/messages` - List messages
- `POST /conversations/{id}/messages` - Send message

## Testing Endpoints in Swagger UI

### 1. Authentication Flow

**Step 1: Register a new user**
1. Navigate to `/auth/register` POST endpoint
2. Click "Try it out"
3. Fill in the example request:
```json
{
  "email": "testuser@example.com",
  "password": "password123",
  "first_name": "Test",
  "last_name": "User",
  "company_name": "Test Company"
}
```
4. Click "Execute"
5. Copy the returned `token`

**Step 2: Set authorization header**
1. Click "Authorize" button at top of page
2. Select "Bearer Token"
3. Paste the token you received
4. Click "Authorize" then "Close"

### 2. Test Drivers Endpoint

Now you can test other endpoints:

1. Navigate to `GET /drivers`
2. Click "Try it out"
3. Leave parameters default or customize
4. Click "Execute"
5. See the response with your company's drivers

### 3. Create a Load

1. Navigate to `POST /loads`
2. Click "Try it out"
3. Fill in required fields:
```json
{
  "reference_number": "LOAD-001",
  "pickup_address": "123 Main St",
  "pickup_city": "New York",
  "pickup_state": "NY",
  "pickup_zip": "10001",
  "pickup_date": "2025-11-26T08:00:00Z",
  "delivery_address": "456 Oak Ave",
  "delivery_city": "Boston",
  "delivery_state": "MA",
  "delivery_zip": "02101",
  "delivery_date": "2025-11-27T17:00:00Z",
  "rate": 1500
}
```
4. Click "Execute"

### 4. Test Error Handling

Try creating invalid requests to see error responses:

**Invalid email format:**
```json
{
  "email": "not-an-email",
  "password": "password123",
  "first_name": "Test",
  "last_name": "User"
}
```

**Missing required field:**
```json
{
  "email": "test@example.com"
}
```

## Security Testing

### Test Authentication
1. Try calling `/drivers` without setting Authorization header
2. You should get a 401 Unauthorized error

### Test Multi-Tenant Isolation
1. Register two users with different companies
2. User 1 logs in and creates a load
3. User 2 logs in and lists loads
4. User 2 should NOT see User 1's load (multi-tenant isolation)

## Response Format

All successful responses follow this format:

```json
{
  "success": true,
  "data": { /* actual data */ },
  "timestamp": "2025-11-25T12:00:00Z"
}
```

Paginated responses include pagination info:

```json
{
  "success": true,
  "data": [ /* array of items */ ],
  "pagination": {
    "total": 100,
    "page": 1,
    "limit": 10,
    "totalPages": 10
  },
  "timestamp": "2025-11-25T12:00:00Z"
}
```

Error responses:

```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE",
  "timestamp": "2025-11-25T12:00:00Z"
}
```

## HTTP Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (missing/invalid JWT)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict
- `500` - Internal Server Error

## Query Parameters

List endpoints support pagination:
- `page` (default: 1)
- `limit` (default: 10, max: 100)

Filter parameters vary by endpoint:
- `search` - Search by text
- `status` - Filter by status
- `date_start`, `date_end` - Date range filtering

## Testing Tools

### Postman Integration

1. Copy OpenAPI spec to Postman:
   - Open Postman
   - File → Import
   - Select the `openapi.yaml` file
   - Collections will be auto-generated

2. Set up environment variables:
   - Create a new environment
   - Set `base_url` = `http://localhost:3002/api/v1`
   - Set `token` = paste your JWT token
   - Use `{{base_url}}/endpoint` in your requests
   - Use `Bearer {{token}}` in Authorization header

### cURL Examples

**Login:**
```bash
curl -X POST http://localhost:3002/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

**Get Drivers (with token):**
```bash
curl -X GET http://localhost:3002/api/v1/drivers \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

**Create Load:**
```bash
curl -X POST http://localhost:3002/api/v1/loads \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "reference_number": "LOAD-001",
    "pickup_address": "123 Main St",
    "pickup_city": "New York",
    "pickup_state": "NY",
    "pickup_zip": "10001",
    "pickup_date": "2025-11-26T08:00:00Z",
    "delivery_address": "456 Oak Ave",
    "delivery_city": "Boston",
    "delivery_state": "MA",
    "delivery_zip": "02101",
    "delivery_date": "2025-11-27T17:00:00Z",
    "rate": 1500
  }'
```

## Common Issues

### CORS Errors
If testing from a browser, the API may need CORS headers configured. Add to your API:

```typescript
import cors from 'cors'

app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:3002'],
  credentials: true,
}))
```

### Invalid Token
- JWT tokens expire (default: 24 hours)
- Re-authenticate by calling `/auth/login` again
- Copy the new token and update Authorization header

### 404 Not Found
- Verify the resource exists
- Check resource ownership (multi-tenant isolation)
- Ensure you're using correct resource IDs

## Next Steps

After testing endpoints:
1. Review test coverage gaps
2. Set up automated integration tests
3. Implement performance benchmarks
4. Add request/response logging
5. Set up API monitoring

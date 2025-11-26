# FED-TMS API Endpoints Reference

**Base URL**: `http://localhost:3002/api/v1`
**Version**: 1.0
**Last Updated**: 2025-11-25

---

## Table of Contents

1. [Authentication](#authentication)
2. [Users](#users)
3. [Drivers](#drivers)
4. [Loads](#loads)
5. [Invoices](#invoices)
6. [Payments](#payments)
7. [Notifications](#notifications)
8. [Conversations](#conversations)

---

## Authentication

### POST /auth/login
**Description**: Authenticate user and receive JWT token
**Auth**: None (public)
**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```
**Response**:
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGc...",
    "user": {
      "id": "user-123",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe"
    },
    "roles": [
      {
        "id": "role-123",
        "name": "admin"
      }
    ]
  }
}
```

### POST /auth/register
**Description**: Register new user account
**Auth**: None (public)
**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe",
  "company_name": "My Company" // optional
}
```
**Response**: Same as login (auto-login after registration)

### GET /auth/me
**Description**: Get current authenticated user
**Auth**: Required (JWT)
**Response**:
```json
{
  "success": true,
  "data": {
    "id": "user-123",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "roles": [...]
  }
}
```

---

## Users

### GET /users
**Description**: List all users in company
**Auth**: Required
**Query Parameters**:
- `page` (integer): Page number (default: 1)
- `limit` (integer): Items per page (default: 10)
- `search` (string): Search by name or email
- `status` (string): Filter by status

**Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "user-123",
      "email": "user@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "phone": "+1234567890"
    }
  ],
  "pagination": {
    "total": 50,
    "page": 1,
    "limit": 10,
    "totalPages": 5
  }
}
```

### POST /users
**Description**: Create new user
**Auth**: Required
**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "password123",
  "first_name": "John",
  "last_name": "Doe",
  "phone": "+1234567890",
  "role_id": "role-123"
}
```

### GET /users/[id]
**Description**: Get user by ID
**Auth**: Required
**Response**:
```json
{
  "success": true,
  "data": {
    "id": "user-123",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "roles": [...]
  }
}
```

### PUT /users/[id]
**Description**: Update user
**Auth**: Required
**Request Body**:
```json
{
  "first_name": "Jane",
  "last_name": "Smith",
  "phone": "+1234567890"
}
```

### DELETE /users/[id]
**Description**: Delete user
**Auth**: Required

---

## Drivers

### GET /drivers
**Description**: List all drivers
**Auth**: Required
**Query Parameters**:
- `page`, `limit`, `search`, `status`
- `license_class` (string): Filter by license class

### POST /drivers
**Description**: Create new driver
**Auth**: Required
**Request Body**:
```json
{
  "user_id": "user-123",
  "license_number": "DL123456",
  "license_class": "A",
  "vehicle_type": "truck",
  "vehicle_vin": "VIN123456",
  "vehicle_plate": "ABC123"
}
```

### GET /drivers/[id]
**Description**: Get driver details
**Auth**: Required

### PUT /drivers/[id]
**Description**: Update driver information
**Auth**: Required
**Request Body**:
```json
{
  "license_class": "B",
  "status": "active"
}
```

### DELETE /drivers/[id]
**Description**: Delete driver
**Auth**: Required

---

## Driver Documents

### GET /drivers/[id]/documents
**Description**: List driver documents
**Auth**: Required
**Query Parameters**: `page`, `limit`

### POST /drivers/[id]/documents
**Description**: Upload driver document
**Auth**: Required
**Request Body**:
```json
{
  "type": "license",
  "document_url": "https://...",
  "expiry_date": "2026-01-01T00:00:00Z"
}
```

### GET /drivers/[id]/documents/[docId]
**Description**: Get specific document
**Auth**: Required

### PUT /drivers/[id]/documents/[docId]
**Description**: Update document
**Auth**: Required

### DELETE /drivers/[id]/documents/[docId]
**Description**: Delete document
**Auth**: Required

---

## Driver Locations

### GET /drivers/[id]/locations
**Description**: Get driver location history
**Auth**: Required
**Query Parameters**: `page`, `limit`

### POST /drivers/[id]/locations
**Description**: Update driver location
**Auth**: Required
**Request Body**:
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "accuracy": 10
}
```

---

## Driver Ratings

### GET /drivers/[id]/ratings
**Description**: Get driver ratings
**Auth**: Required
**Response includes**:
- List of ratings
- Average rating
- Total rating count

### POST /drivers/[id]/ratings
**Description**: Add rating to driver
**Auth**: Required
**Request Body**:
```json
{
  "rating": 5,
  "comment": "Excellent service",
  "load_id": "load-123"
}
```

---

## Loads

### GET /loads
**Description**: List all loads
**Auth**: Required
**Query Parameters**:
- `page`, `limit`, `search`, `status`
- `pickup_date_start`, `pickup_date_end` (ISO strings)

### POST /loads
**Description**: Create new load
**Auth**: Required
**Request Body**:
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
  "rate": 1500,
  "commodity": "Electronics",
  "weight": 5000,
  "hazmat": false
}
```

### GET /loads/[id]
**Description**: Get load details
**Auth**: Required

### PUT /loads/[id]
**Description**: Update load
**Auth**: Required
**Request Body**:
```json
{
  "status": "in_transit",
  "rate": 1600
}
```

### DELETE /loads/[id]
**Description**: Delete load
**Auth**: Required

---

## Load Assignments

### GET /loads/[id]/assignments
**Description**: List load assignments
**Auth**: Required

### POST /loads/[id]/assignments
**Description**: Assign driver to load
**Auth**: Required
**Request Body**:
```json
{
  "driver_id": "driver-123"
}
```

---

## Load Tracking

### GET /loads/[id]/tracking
**Description**: Get load tracking history
**Auth**: Required
**Query Parameters**: `page`, `limit`

### POST /loads/[id]/tracking
**Description**: Update load tracking
**Auth**: Required
**Request Body**:
```json
{
  "status": "in_transit",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "notes": "Stopped for break"
}
```
**Statuses**: `pickup_arrived`, `pickup_completed`, `in_transit`, `delivery_arrived`, `delivered`, `failed`

---

## Load Documents

### GET /loads/[id]/documents
**Description**: List load documents
**Auth**: Required

### POST /loads/[id]/documents
**Description**: Upload load document
**Auth**: Required
**Request Body**:
```json
{
  "type": "bill_of_lading",
  "url": "https://..."
}
```

---

## Invoices

### GET /invoices
**Description**: List invoices
**Auth**: Required
**Query Parameters**: `page`, `limit`, `search`, `status`, `date_start`, `date_end`

### POST /invoices
**Description**: Create invoice
**Auth**: Required
**Request Body**:
```json
{
  "invoice_number": "INV-001",
  "load_id": "load-123",
  "amount": 1500,
  "due_date": "2025-12-25T00:00:00Z",
  "description": "Freight charges"
}
```

### GET /invoices/[id]
**Description**: Get invoice with payment info
**Auth**: Required
**Response includes**: Line items, payments, calculated totals

### PUT /invoices/[id]
**Description**: Update invoice
**Auth**: Required
**Request Body**:
```json
{
  "status": "sent",
  "amount": 1600
}
```

### DELETE /invoices/[id]
**Description**: Delete invoice
**Auth**: Required

---

## Payments

### GET /payments
**Description**: List payments
**Auth**: Required
**Query Parameters**: `page`, `limit`, `status`

### POST /payments
**Description**: Create payment
**Auth**: Required
**Request Body**:
```json
{
  "invoice_id": "invoice-123",
  "amount": 1500,
  "method": "card",
  "transaction_id": "txn-123"
}
```

### GET /payments/[id]
**Description**: Get payment details
**Auth**: Required

### PUT /payments/[id]
**Description**: Update payment
**Auth**: Required
**Request Body**:
```json
{
  "status": "completed",
  "amount": 1600
}
```
**Note**: Cannot update completed or refunded payments

### DELETE /payments/[id]
**Description**: Delete payment
**Auth**: Required
**Note**: Cannot delete completed or refunded payments

---

## Notifications

### GET /notifications
**Description**: Get user's notifications
**Auth**: Required
**Query Parameters**: `page`, `limit`
**Response**: Paginated notifications ordered by created_at desc

### POST /notifications
**Description**: Create notification (admin/system)
**Auth**: Required
**Request Body**:
```json
{
  "user_id": "user-123",
  "type": "assignment",
  "title": "New Load Assignment",
  "message": "You have been assigned to load LOAD-001",
  "link": "http://localhost:3000/loads/load-123"
}
```

### GET /notifications/[id]
**Description**: Get specific notification
**Auth**: Required

### PUT /notifications/[id]
**Description**: Update notification (mark as read)
**Auth**: Required
**Request Body**:
```json
{
  "read": true
}
```

### DELETE /notifications/[id]
**Description**: Delete notification
**Auth**: Required

---

## Conversations

### GET /conversations
**Description**: List user's conversations
**Auth**: Required
**Query Parameters**: `page`, `limit`

### POST /conversations
**Description**: Create conversation
**Auth**: Required
**Request Body**:
```json
{
  "name": "Dispatch Team",
  "is_group": true,
  "participant_ids": ["user-123", "user-456"]
}
```

### GET /conversations/[id]
**Description**: Get conversation with messages
**Auth**: Required
**Response includes**: Participants, last 50 messages

### PUT /conversations/[id]
**Description**: Update conversation
**Auth**: Required
**Request Body**:
```json
{
  "name": "Updated Team Name"
}
```

### DELETE /conversations/[id]
**Description**: Delete conversation
**Auth**: Required

---

## Conversation Messages

### GET /conversations/[id]/messages
**Description**: List messages in conversation
**Auth**: Required
**Query Parameters**: `page`, `limit`

### POST /conversations/[id]/messages
**Description**: Send message
**Auth**: Required
**Request Body**:
```json
{
  "content": "Message text",
  "message_type": "text",
  "attachment_url": "https://..." // optional
}
```

---

## Error Responses

All error responses follow this format:

```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE",
  "timestamp": "2025-11-25T12:00:00Z"
}
```

### HTTP Status Codes

- `200` - OK
- `201` - Created
- `400` - Bad Request (validation error)
- `401` - Unauthorized (missing/invalid JWT)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `409` - Conflict
- `500` - Internal Server Error

---

## Rate Limiting

Currently not implemented. Add headers for future rate limiting:
- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`

---

## Pagination

All list endpoints support:
- `page` (default: 1)
- `limit` (default: 10, max: 100)

Response includes pagination info:
```json
{
  "pagination": {
    "total": 100,
    "page": 1,
    "limit": 10,
    "totalPages": 10
  }
}
```

---

## Multi-Tenant

All endpoints automatically filter by authenticated user's company.
No global queries across companies are possible.

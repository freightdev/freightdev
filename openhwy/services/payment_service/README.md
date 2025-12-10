# Payment Webhook Service

Stripe webhook handler for HWY-TMS subscription management.

## Features

- Stripe webhook signature verification
- Subscription lifecycle management
- Payment tracking
- Automatic tier upgrades/downgrades
- Grace period handling for failed payments

## Handled Events

| Event | Action |
|-------|--------|
| `customer.subscription.created` | Create subscription record |
| `customer.subscription.updated` | Update tier, status, or period |
| `customer.subscription.deleted` | Downgrade to free tier |
| `invoice.payment_succeeded` | Mark subscription as active |
| `invoice.payment_failed` | Mark as past_due + 7-day grace |

## API Endpoints

### POST /webhook/stripe
Handle Stripe webhook events.

**Headers:**
```
stripe-signature: t=timestamp,v1=signature
Content-Type: application/json
```

**Request:** (Stripe event object)

**Response:**
```json
{
  "received": true
}
```

## Development

```bash
# Copy environment file
cp .env.example .env

# Add your Stripe keys
# Get webhook secret with: stripe listen --forward-to localhost:8002/webhook/stripe

# Run locally
cargo run

# Test with Stripe CLI
stripe trigger customer.subscription.created
```

## Testing

```bash
# Forward webhooks to local server
stripe listen --forward-to localhost:8002/webhook/stripe

# Trigger test events
stripe trigger customer.subscription.created
stripe trigger invoice.payment_succeeded
stripe trigger invoice.payment_failed
stripe trigger customer.subscription.deleted
```

## Environment Variables

- `DATABASE_URL`: SurrealDB connection
- `STRIPE_SECRET_KEY`: Stripe secret key
- `STRIPE_WEBHOOK_SECRET`: Webhook signing secret
- `PORT`: Server port (default: 8002)

## Security

- HMAC-SHA256 signature verification
- Constant-time comparison
- Idempotent event handling

## Production Deployment

```bash
# Build Docker image
docker build -t hwy-tms/payment-service:latest .

# Run container
docker run -p 8002:8002 \
  -e DATABASE_URL=surrealdb:8000 \
  -e STRIPE_SECRET_KEY=sk_live_xxx \
  -e STRIPE_WEBHOOK_SECRET=whsec_xxx \
  hwy-tms/payment-service:latest
```

## Subscription Flow

```
1. User subscribes via Stripe Checkout
2. Stripe sends customer.subscription.created
3. Service updates SurrealDB: tier=pro, status=active
4. User's app receives updated tier on next /auth/validate

Payment fails:
1. Stripe sends invoice.payment_failed
2. Service updates: status=past_due, grace_period_ends=+7days
3. User's app shows warning banner

After 7 days (Stripe retries exhausted):
1. Stripe sends customer.subscription.deleted
2. Service updates: tier=free, status=cancelled
3. User downgraded to free limits
```

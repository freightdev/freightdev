# SurrealDB Schema for HWY-TMS

## Overview

This document defines the complete SurrealDB schema for HWY-TMS, converted from the original PostgreSQL design.

**Database**: SurrealDB (embedded + distributed)
**Namespace**: `hwytms`
**Database**: `production` (or `development` for local)

---

## Schema Definition

### 1. Users Table

Stores all user accounts (dispatchers and drivers).

```surql
DEFINE TABLE users SCHEMAFULL;

DEFINE FIELD id ON users TYPE record<users>;
DEFINE FIELD email ON users TYPE string ASSERT string::is::email($value);
DEFINE FIELD password_hash ON users TYPE string;
DEFINE FIELD role ON users TYPE string ASSERT $value IN ['dispatcher', 'driver'];
DEFINE FIELD created_at ON users TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON users TYPE datetime DEFAULT time::now();

-- Indexes
DEFINE INDEX unique_email ON users COLUMNS email UNIQUE;
DEFINE INDEX idx_role ON users COLUMNS role;
```

---

### 2. Subscriptions Table

Manages subscription tiers and payment status.

```surql
DEFINE TABLE subscriptions SCHEMAFULL;

DEFINE FIELD id ON subscriptions TYPE record<subscriptions>;
DEFINE FIELD user_id ON subscriptions TYPE record<users>;
DEFINE FIELD tier ON subscriptions TYPE string DEFAULT 'free' ASSERT $value IN ['free', 'pro', 'enterprise'];
DEFINE FIELD status ON subscriptions TYPE string ASSERT $value IN ['active', 'past_due', 'cancelled', 'trialing'];

-- Stripe data
DEFINE FIELD stripe_customer_id ON subscriptions TYPE option<string>;
DEFINE FIELD stripe_subscription_id ON subscriptions TYPE option<string>;
DEFINE FIELD payment_method ON subscriptions TYPE option<string>; -- 'card', 'paypal', 'apple_pay'

-- Billing periods
DEFINE FIELD current_period_start ON subscriptions TYPE option<datetime>;
DEFINE FIELD current_period_end ON subscriptions TYPE option<datetime>;
DEFINE FIELD grace_period_ends ON subscriptions TYPE option<datetime>;
DEFINE FIELD cancel_at_period_end ON subscriptions TYPE bool DEFAULT false;

DEFINE FIELD created_at ON subscriptions TYPE datetime DEFAULT time::now();
DEFINE FIELD updated_at ON subscriptions TYPE datetime DEFAULT time::now();

-- Indexes
DEFINE INDEX idx_user_id ON subscriptions COLUMNS user_id UNIQUE;
DEFINE INDEX idx_stripe_customer ON subscriptions COLUMNS stripe_customer_id;
DEFINE INDEX idx_stripe_subscription ON subscriptions COLUMNS stripe_subscription_id;
DEFINE INDEX idx_status ON subscriptions COLUMNS status;
```

---

### 3. Tier Features Table

Defines what each tier can do (could also be hardcoded).

```surql
DEFINE TABLE tier_features SCHEMAFULL;

DEFINE FIELD tier ON tier_features TYPE string ASSERT $value IN ['free', 'pro', 'enterprise'];
DEFINE FIELD max_drivers ON tier_features TYPE int;
DEFINE FIELD max_loads ON tier_features TYPE int; -- -1 for unlimited
DEFINE FIELD ai_agents_enabled ON tier_features TYPE bool DEFAULT false;
DEFINE FIELD custom_branding ON tier_features TYPE bool DEFAULT false;
DEFINE FIELD priority_support ON tier_features TYPE bool DEFAULT false;
DEFINE FIELD dedicated_support ON tier_features TYPE bool DEFAULT false;

-- Primary key
DEFINE INDEX unique_tier ON tier_features COLUMNS tier UNIQUE;
```

**Seed Data:**
```surql
CREATE tier_features CONTENT {
    tier: 'free',
    max_drivers: 3,
    max_loads: 10,
    ai_agents_enabled: false,
    custom_branding: false,
    priority_support: false,
    dedicated_support: false
};

CREATE tier_features CONTENT {
    tier: 'pro',
    max_drivers: 20,
    max_loads: -1,
    ai_agents_enabled: true,
    custom_branding: false,
    priority_support: true,
    dedicated_support: false
};

CREATE tier_features CONTENT {
    tier: 'enterprise',
    max_drivers: -1,
    max_loads: -1,
    ai_agents_enabled: true,
    custom_branding: true,
    priority_support: true,
    dedicated_support: true
};
```

---

### 4. Nebula Certificates Table

Stores VPN certificates for Nebula mesh network.

```surql
DEFINE TABLE nebula_certs SCHEMAFULL;

DEFINE FIELD id ON nebula_certs TYPE record<nebula_certs>;
DEFINE FIELD user_id ON nebula_certs TYPE record<users>;
DEFINE FIELD nebula_ip ON nebula_certs TYPE string; -- e.g., "10.42.1.1"
DEFINE FIELD cert_pem ON nebula_certs TYPE string;
DEFINE FIELD key_pem ON nebula_certs TYPE string;
DEFINE FIELD issued_at ON nebula_certs TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON nebula_certs TYPE datetime;
DEFINE FIELD revoked ON nebula_certs TYPE bool DEFAULT false;
DEFINE FIELD revoked_at ON nebula_certs TYPE option<datetime>;

-- Indexes
DEFINE INDEX idx_user_id ON nebula_certs COLUMNS user_id;
DEFINE INDEX unique_nebula_ip ON nebula_certs COLUMNS nebula_ip UNIQUE;
```

---

### 5. Invites Table

Magic links for driver onboarding.

```surql
DEFINE TABLE invites SCHEMAFULL;

DEFINE FIELD id ON invites TYPE record<invites>; -- This serves as the token (UUID)
DEFINE FIELD dispatcher_id ON invites TYPE record<users>;
DEFINE FIELD driver_name ON invites TYPE option<string>;
DEFINE FIELD contact ON invites TYPE option<string>; -- email or phone
DEFINE FIELD driver_cert_pem ON invites TYPE option<string>; -- Pre-generated
DEFINE FIELD driver_key_pem ON invites TYPE option<string>;
DEFINE FIELD driver_nebula_ip ON invites TYPE option<string>;
DEFINE FIELD created_at ON invites TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON invites TYPE datetime;
DEFINE FIELD used ON invites TYPE bool DEFAULT false;
DEFINE FIELD used_at ON invites TYPE option<datetime>;

-- Indexes
DEFINE INDEX idx_dispatcher_id ON invites COLUMNS dispatcher_id;
DEFINE INDEX idx_used ON invites COLUMNS used;
```

---

### 6. Connections Table

Tracks dispatcher ↔ driver relationships.

```surql
DEFINE TABLE connections SCHEMAFULL;

DEFINE FIELD id ON connections TYPE record<connections>;
DEFINE FIELD dispatcher_id ON connections TYPE record<users>;
DEFINE FIELD driver_id ON connections TYPE record<users>;
DEFINE FIELD dispatcher_nebula_ip ON connections TYPE string;
DEFINE FIELD driver_nebula_ip ON connections TYPE string;
DEFINE FIELD status ON connections TYPE string DEFAULT 'active' ASSERT $value IN ['active', 'paused', 'terminated'];
DEFINE FIELD created_at ON connections TYPE datetime DEFAULT time::now();
DEFINE FIELD last_seen ON connections TYPE datetime DEFAULT time::now();

-- Indexes
DEFINE INDEX idx_dispatcher_id ON connections COLUMNS dispatcher_id;
DEFINE INDEX idx_driver_id ON connections COLUMNS driver_id;
DEFINE INDEX unique_connection ON connections COLUMNS dispatcher_id, driver_id UNIQUE;
```

---

### 7. Refresh Tokens Table

For JWT refresh flow.

```surql
DEFINE TABLE refresh_tokens SCHEMAFULL;

DEFINE FIELD id ON refresh_tokens TYPE record<refresh_tokens>;
DEFINE FIELD user_id ON refresh_tokens TYPE record<users>;
DEFINE FIELD token ON refresh_tokens TYPE string;
DEFINE FIELD expires_at ON refresh_tokens TYPE datetime;
DEFINE FIELD created_at ON refresh_tokens TYPE datetime DEFAULT time::now();
DEFINE FIELD revoked ON refresh_tokens TYPE bool DEFAULT false;

-- Indexes
DEFINE INDEX unique_token ON refresh_tokens COLUMNS token UNIQUE;
DEFINE INDEX idx_user_id ON refresh_tokens COLUMNS user_id;
```

---

### 8. Payments Table (Optional - for analytics)

Tracks payment history.

```surql
DEFINE TABLE payments SCHEMAFULL;

DEFINE FIELD id ON payments TYPE record<payments>;
DEFINE FIELD user_id ON payments TYPE record<users>;
DEFINE FIELD amount ON payments TYPE int; -- in cents
DEFINE FIELD currency ON payments TYPE string DEFAULT 'USD';
DEFINE FIELD payment_method ON payments TYPE string;
DEFINE FIELD stripe_payment_id ON payments TYPE option<string>;
DEFINE FIELD status ON payments TYPE string ASSERT $value IN ['succeeded', 'failed', 'refunded', 'pending'];
DEFINE FIELD created_at ON payments TYPE datetime DEFAULT time::now();

-- Indexes
DEFINE INDEX idx_user_id ON payments COLUMNS user_id;
DEFINE INDEX idx_stripe_payment_id ON payments COLUMNS stripe_payment_id;
DEFINE INDEX idx_status ON payments COLUMNS status;
```

---

## Relationships

SurrealDB supports graph relationships. Define relations:

```surql
-- User has one subscription
DEFINE TABLE user_subscription SCHEMAFULL;
DEFINE FIELD in ON user_subscription TYPE record<users>;
DEFINE FIELD out ON user_subscription TYPE record<subscriptions>;

-- User has one Nebula certificate
DEFINE TABLE user_cert SCHEMAFULL;
DEFINE FIELD in ON user_cert TYPE record<users>;
DEFINE FIELD out ON user_cert TYPE record<nebula_certs>;

-- Dispatcher has many invites
DEFINE TABLE dispatcher_invites SCHEMAFULL;
DEFINE FIELD in ON dispatcher_invites TYPE record<users>;
DEFINE FIELD out ON dispatcher_invites TYPE record<invites>;

-- Dispatcher connected to many drivers
DEFINE TABLE dispatcher_drivers SCHEMAFULL;
DEFINE FIELD in ON dispatcher_drivers TYPE record<users>; -- dispatcher
DEFINE FIELD out ON dispatcher_drivers TYPE record<users>; -- driver
DEFINE FIELD connection_id ON dispatcher_drivers TYPE record<connections>;
```

---

## Scopes & Permissions

Define authentication scopes:

```surql
-- User scope for JWT authentication
DEFINE SCOPE user SESSION 7d
SIGNIN (
    SELECT * FROM users WHERE email = $email AND crypto::argon2::compare(password_hash, $password)
)
SIGNUP (
    CREATE users CONTENT {
        email: $email,
        password_hash: crypto::argon2::generate($password),
        role: $role,
        created_at: time::now(),
        updated_at: time::now()
    }
);

-- Permissions for users table
DEFINE TABLE users PERMISSIONS
    FOR select WHERE id = $auth.id OR $auth.role = 'admin'
    FOR create, update, delete WHERE id = $auth.id OR $auth.role = 'admin';

-- Permissions for subscriptions table
DEFINE TABLE subscriptions PERMISSIONS
    FOR select WHERE user_id = $auth.id OR $auth.role = 'admin'
    FOR create, update WHERE $auth.role = 'admin'
    FOR delete NONE;

-- Similar permissions for other tables...
```

---

## Common Queries

### Create a new user (signup)
```surql
CREATE users CONTENT {
    email: "dispatcher@example.com",
    password_hash: crypto::argon2::generate("SecurePassword123!"),
    role: "dispatcher",
    created_at: time::now(),
    updated_at: time::now()
};

-- Also create default free subscription
CREATE subscriptions CONTENT {
    user_id: <user_record_id>,
    tier: "free",
    status: "active",
    cancel_at_period_end: false,
    created_at: time::now(),
    updated_at: time::now()
};
```

### Authenticate user (login)
```surql
SELECT * FROM users
WHERE email = "dispatcher@example.com"
  AND crypto::argon2::compare(password_hash, "SecurePassword123!");
```

### Get user with subscription info
```surql
SELECT *,
    (SELECT * FROM subscriptions WHERE user_id = $parent.id)[0] AS subscription
FROM users
WHERE id = users:abc123;
```

### Check if user can add more drivers
```surql
LET $subscription = (SELECT * FROM subscriptions WHERE user_id = users:abc123)[0];
LET $features = (SELECT * FROM tier_features WHERE tier = $subscription.tier)[0];
LET $current_drivers = (SELECT count() FROM connections WHERE dispatcher_id = users:abc123 AND status = 'active')[0];

RETURN $features.max_drivers = -1 OR $current_drivers < $features.max_drivers;
```

### Create invite with pre-generated Nebula cert
```surql
CREATE invites CONTENT {
    dispatcher_id: users:abc123,
    driver_name: "John Doe",
    contact: "john@example.com",
    driver_cert_pem: "-----BEGIN CERTIFICATE-----...",
    driver_key_pem: "-----BEGIN PRIVATE KEY-----...",
    driver_nebula_ip: "10.42.1.2",
    created_at: time::now(),
    expires_at: time::now() + 7d,
    used: false
};
```

### Establish connection (driver accepts invite)
```surql
-- Update invite
UPDATE invites:xyz789 SET
    used = true,
    used_at = time::now();

-- Create connection
CREATE connections CONTENT {
    dispatcher_id: users:dispatcher123,
    driver_id: users:driver456,
    dispatcher_nebula_ip: "10.42.1.1",
    driver_nebula_ip: "10.42.1.2",
    status: "active",
    created_at: time::now(),
    last_seen: time::now()
};
```

### Update subscription (from Stripe webhook)
```surql
UPDATE subscriptions
SET
    tier = "pro",
    status = "active",
    stripe_subscription_id = "sub_xxx",
    current_period_start = time::now(),
    current_period_end = time::now() + 30d,
    updated_at = time::now()
WHERE user_id = users:abc123;
```

### Handle payment failure
```surql
UPDATE subscriptions
SET
    status = "past_due",
    grace_period_ends = time::now() + 7d,
    updated_at = time::now()
WHERE stripe_subscription_id = "sub_xxx";
```

### Revoke Nebula certificate
```surql
UPDATE nebula_certs
SET
    revoked = true,
    revoked_at = time::now()
WHERE user_id = users:driver456;
```

---

## Migration Script

Complete setup script to initialize the database:

```surql
-- Use namespace and database
USE NS hwytms DB production;

-- Define all tables (run the DEFINE TABLE statements above)

-- Seed tier_features
CREATE tier_features CONTENT { tier: 'free', max_drivers: 3, max_loads: 10, ai_agents_enabled: false, custom_branding: false, priority_support: false, dedicated_support: false };
CREATE tier_features CONTENT { tier: 'pro', max_drivers: 20, max_loads: -1, ai_agents_enabled: true, custom_branding: false, priority_support: true, dedicated_support: false };
CREATE tier_features CONTENT { tier: 'enterprise', max_drivers: -1, max_loads: -1, ai_agents_enabled: true, custom_branding: true, priority_support: true, dedicated_support: true };
```

---

## Backup & Restore

### Backup
```bash
surreal export --namespace hwytms --database production --endpoint http://localhost:8000 backup.surql
```

### Restore
```bash
surreal import --namespace hwytms --database production --endpoint http://localhost:8000 backup.surql
```

---

## Performance Considerations

1. **Indexes**: All foreign keys and frequently queried fields are indexed
2. **Connections**: Use connection pooling in Rust services
3. **Queries**: Use SELECT with specific fields, not SELECT *
4. **Caching**: Cache tier_features (rarely changes)
5. **Transactions**: Use transactions for multi-step operations (create user + subscription)

---

Last Updated: December 9, 2025

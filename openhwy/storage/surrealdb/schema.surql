-- HWY-TMS SurrealDB Schema
-- Version: 1.0.0
-- Date: December 9, 2025

-- Use namespace and database
USE NS hwytms DB production;

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================

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

-- ============================================================================
-- 2. SUBSCRIPTIONS TABLE
-- ============================================================================

DEFINE TABLE subscriptions SCHEMAFULL;

DEFINE FIELD id ON subscriptions TYPE record<subscriptions>;
DEFINE FIELD user_id ON subscriptions TYPE record<users>;
DEFINE FIELD tier ON subscriptions TYPE string DEFAULT 'free' ASSERT $value IN ['free', 'pro', 'enterprise'];
DEFINE FIELD status ON subscriptions TYPE string ASSERT $value IN ['active', 'past_due', 'cancelled', 'trialing'];

-- Stripe data
DEFINE FIELD stripe_customer_id ON subscriptions TYPE option<string>;
DEFINE FIELD stripe_subscription_id ON subscriptions TYPE option<string>;
DEFINE FIELD payment_method ON subscriptions TYPE option<string>;

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

-- ============================================================================
-- 3. TIER FEATURES TABLE
-- ============================================================================

DEFINE TABLE tier_features SCHEMAFULL;

DEFINE FIELD tier ON tier_features TYPE string ASSERT $value IN ['free', 'pro', 'enterprise'];
DEFINE FIELD max_drivers ON tier_features TYPE int;
DEFINE FIELD max_loads ON tier_features TYPE int;
DEFINE FIELD ai_agents_enabled ON tier_features TYPE bool DEFAULT false;
DEFINE FIELD custom_branding ON tier_features TYPE bool DEFAULT false;
DEFINE FIELD priority_support ON tier_features TYPE bool DEFAULT false;
DEFINE FIELD dedicated_support ON tier_features TYPE bool DEFAULT false;

-- Indexes
DEFINE INDEX unique_tier ON tier_features COLUMNS tier UNIQUE;

-- ============================================================================
-- 4. NEBULA CERTIFICATES TABLE
-- ============================================================================

DEFINE TABLE nebula_certs SCHEMAFULL;

DEFINE FIELD id ON nebula_certs TYPE record<nebula_certs>;
DEFINE FIELD user_id ON nebula_certs TYPE record<users>;
DEFINE FIELD nebula_ip ON nebula_certs TYPE string;
DEFINE FIELD cert_pem ON nebula_certs TYPE string;
DEFINE FIELD key_pem ON nebula_certs TYPE string;
DEFINE FIELD issued_at ON nebula_certs TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON nebula_certs TYPE datetime;
DEFINE FIELD revoked ON nebula_certs TYPE bool DEFAULT false;
DEFINE FIELD revoked_at ON nebula_certs TYPE option<datetime>;

-- Indexes
DEFINE INDEX idx_user_id ON nebula_certs COLUMNS user_id;
DEFINE INDEX unique_nebula_ip ON nebula_certs COLUMNS nebula_ip UNIQUE;

-- ============================================================================
-- 5. INVITES TABLE
-- ============================================================================

DEFINE TABLE invites SCHEMAFULL;

DEFINE FIELD id ON invites TYPE record<invites>;
DEFINE FIELD dispatcher_id ON invites TYPE record<users>;
DEFINE FIELD driver_name ON invites TYPE option<string>;
DEFINE FIELD contact ON invites TYPE option<string>;
DEFINE FIELD driver_cert_pem ON invites TYPE option<string>;
DEFINE FIELD driver_key_pem ON invites TYPE option<string>;
DEFINE FIELD driver_nebula_ip ON invites TYPE option<string>;
DEFINE FIELD created_at ON invites TYPE datetime DEFAULT time::now();
DEFINE FIELD expires_at ON invites TYPE datetime;
DEFINE FIELD used ON invites TYPE bool DEFAULT false;
DEFINE FIELD used_at ON invites TYPE option<datetime>;

-- Indexes
DEFINE INDEX idx_dispatcher_id ON invites COLUMNS dispatcher_id;
DEFINE INDEX idx_used ON invites COLUMNS used;

-- ============================================================================
-- 6. CONNECTIONS TABLE
-- ============================================================================

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

-- ============================================================================
-- 7. REFRESH TOKENS TABLE
-- ============================================================================

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

-- ============================================================================
-- 8. PAYMENTS TABLE
-- ============================================================================

DEFINE TABLE payments SCHEMAFULL;

DEFINE FIELD id ON payments TYPE record<payments>;
DEFINE FIELD user_id ON payments TYPE record<users>;
DEFINE FIELD amount ON payments TYPE int;
DEFINE FIELD currency ON payments TYPE string DEFAULT 'USD';
DEFINE FIELD payment_method ON payments TYPE string;
DEFINE FIELD stripe_payment_id ON payments TYPE option<string>;
DEFINE FIELD status ON payments TYPE string ASSERT $value IN ['succeeded', 'failed', 'refunded', 'pending'];
DEFINE FIELD created_at ON payments TYPE datetime DEFAULT time::now();

-- Indexes
DEFINE INDEX idx_user_id ON payments COLUMNS user_id;
DEFINE INDEX idx_stripe_payment_id ON payments COLUMNS stripe_payment_id;
DEFINE INDEX idx_status ON payments COLUMNS status;

-- ============================================================================
-- SEED DATA: TIER FEATURES
-- ============================================================================

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

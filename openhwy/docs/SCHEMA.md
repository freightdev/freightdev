-- ================================================================
-- OPENHWY TMS - COMPLETE ENTERPRISE DATABASE SCHEMA
-- ================================================================
-- Version: 0.0
-- Database: PostgreSQL 16+
-- Purpose: Full-featured Transportation Management System
-- ================================================================

-- Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- For geospatial data
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search
CREATE EXTENSION IF NOT EXISTS "btree_gin"; -- For better indexing

-- ================================================================
-- CORE COMPANY & USER MANAGEMENT
-- ================================================================

CREATE TABLE companies (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
company_type VARCHAR(50) NOT NULL CHECK (company_type IN ('carrier', 'broker', 'shipper', '3pl', 'dispatcher', 'hybrid')),
legal_name VARCHAR(255) NOT NULL,
dba_name VARCHAR(255),
mc_number VARCHAR(50), -- Motor Carrier Authority Number
dot_number VARCHAR(50) UNIQUE, -- USDOT Number
scac_code VARCHAR(4), -- Standard Carrier Alpha Code
ein VARCHAR(20), -- Employer Identification Number

    -- Contact Information
    email VARCHAR(255),
    phone VARCHAR(50),
    fax VARCHAR(50),
    website VARCHAR(255),

    -- Address
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),
    country VARCHAR(3) DEFAULT 'USA',

    -- Business Details
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'pending')),
    operating_authority VARCHAR(100), -- Interstate, Intrastate
    insurance_provider VARCHAR(255),
    insurance_policy_number VARCHAR(100),
    insurance_expiry DATE,

    -- Financial
    factoring_company_id UUID, -- Self-reference or external
    payment_terms INTEGER DEFAULT 30, -- Net days
    credit_limit DECIMAL(15, 2),

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID,
    metadata JSONB DEFAULT '{}'::jsonb

);

CREATE TABLE users (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
company_id UUID REFERENCES companies(id) ON DELETE CASCADE,

    -- Authentication
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    password_hash TEXT NOT NULL,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret TEXT,

    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'dispatcher', 'driver', 'broker', 'accountant', 'manager', 'viewer')),

    -- Status
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'pending')),
    last_login TIMESTAMP,

    -- Permissions (JSONB for flexible permissions)
    permissions JSONB DEFAULT '{}'::jsonb,

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb

);

CREATE TABLE user_sessions (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
user_id UUID REFERENCES users(id) ON DELETE CASCADE,
token TEXT UNIQUE NOT NULL,
ip_address INET,
user_agent TEXT,
expires_at TIMESTAMP NOT NULL,
created_at TIMESTAMP DEFAULT NOW()
);

-- ================================================================
-- DRIVER MANAGEMENT
-- ================================================================

CREATE TABLE drivers (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
user_id UUID REFERENCES users(id) ON DELETE SET NULL,

    -- Personal Information
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50) NOT NULL,
    date_of_birth DATE,
    ssn_encrypted TEXT, -- Encrypted SSN

    -- Address
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),

    -- License Information
    cdl_number VARCHAR(50) UNIQUE NOT NULL,
    cdl_state VARCHAR(50),
    cdl_class VARCHAR(10) CHECK (cdl_class IN ('A', 'B', 'C')),
    cdl_expiry DATE NOT NULL,
    endorsements TEXT[], -- ['H', 'N', 'T', 'X'] Hazmat, Tank, etc

    -- Employment
    hire_date DATE,
    termination_date DATE,
    employment_status VARCHAR(50) DEFAULT 'active' CHECK (employment_status IN ('active', 'inactive', 'on_leave', 'terminated')),
    driver_type VARCHAR(50) CHECK (driver_type IN ('company', 'owner_operator', 'lease', 'temporary')),

    -- Pay Information
    pay_type VARCHAR(50) CHECK (pay_type IN ('per_mile', 'per_hour', 'per_load', 'percentage', 'salary')),
    pay_rate DECIMAL(10, 4),
    percentage_split DECIMAL(5, 2), -- For percentage pay

    -- Compliance
    medical_card_expiry DATE,
    drug_test_date DATE,
    background_check_date DATE,

    -- Performance
    safety_score DECIMAL(5, 2),
    on_time_percentage DECIMAL(5, 2),
    total_miles BIGINT DEFAULT 0,
    total_loads INTEGER DEFAULT 0,

    -- Current Status
    current_status VARCHAR(50) DEFAULT 'available' CHECK (current_status IN ('available', 'on_duty', 'off_duty', 'sleeper', 'driving', 'on_leave')),
    current_location GEOGRAPHY(POINT),
    last_location_update TIMESTAMP,

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb

);

CREATE TABLE driver_documents (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
document_type VARCHAR(100) NOT NULL, -- 'cdl', 'medical_card', 'w9', etc
file_url TEXT NOT NULL,
file_name VARCHAR(255),
expiry_date DATE,
uploaded_at TIMESTAMP DEFAULT NOW(),
uploaded_by UUID REFERENCES users(id)
);

CREATE TABLE driver_violations (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
violation_type VARCHAR(100) NOT NULL,
violation_date DATE NOT NULL,
description TEXT,
severity VARCHAR(50) CHECK (severity IN ('minor', 'major', 'critical')),
points INTEGER DEFAULT 0,
fine_amount DECIMAL(10, 2),
resolved BOOLEAN DEFAULT FALSE,
created_at TIMESTAMP DEFAULT NOW()
);

-- ================================================================
-- ASSET MANAGEMENT (TRUCKS & TRAILERS)
-- ================================================================

CREATE TABLE trucks (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
company_id UUID REFERENCES companies(id) ON DELETE CASCADE,

    -- Identification
    truck_number VARCHAR(50) UNIQUE NOT NULL,
    vin VARCHAR(17) UNIQUE NOT NULL,
    license_plate VARCHAR(20),
    license_plate_state VARCHAR(50),

    -- Specifications
    make VARCHAR(100),
    model VARCHAR(100),
    year INTEGER,
    truck_type VARCHAR(50) CHECK (truck_type IN ('day_cab', 'sleeper', 'straight', 'box_truck', 'flatbed')),

    -- Capacity
    gvwr INTEGER, -- Gross Vehicle Weight Rating
    empty_weight INTEGER,
    max_payload INTEGER,

    -- Ownership
    ownership_type VARCHAR(50) CHECK (ownership_type IN ('owned', 'leased', 'owner_operator')),
    owner_operator_id UUID REFERENCES drivers(id),
    lease_expiry DATE,

    -- Status
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'maintenance', 'out_of_service', 'sold')),
    current_driver_id UUID REFERENCES drivers(id),
    current_location GEOGRAPHY(POINT),
    last_location_update TIMESTAMP,

    -- Maintenance
    last_service_date DATE,
    next_service_due DATE,
    odometer_reading BIGINT DEFAULT 0,

    -- Insurance & Registration
    registration_expiry DATE,
    insurance_expiry DATE,
    inspection_expiry DATE,

    -- ELD Integration
    eld_device_id VARCHAR(100),
    eld_provider VARCHAR(100),

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb

);

CREATE TABLE trailers (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
company_id UUID REFERENCES companies(id) ON DELETE CASCADE,

    -- Identification
    trailer_number VARCHAR(50) UNIQUE NOT NULL,
    vin VARCHAR(17) UNIQUE,
    license_plate VARCHAR(20),
    license_plate_state VARCHAR(50),

    -- Specifications
    make VARCHAR(100),
    model VARCHAR(100),
    year INTEGER,
    trailer_type VARCHAR(50) CHECK (trailer_type IN ('dry_van', 'reefer', 'flatbed', 'step_deck', 'lowboy', 'tanker', 'hopper', 'conestoga')),
    length_feet DECIMAL(5, 2),

    -- Capacity
    max_weight INTEGER,
    volume_cubic_feet DECIMAL(10, 2),

    -- Temperature Control (for reefers)
    has_temperature_control BOOLEAN DEFAULT FALSE,
    min_temperature DECIMAL(5, 2),
    max_temperature DECIMAL(5, 2),

    -- Ownership
    ownership_type VARCHAR(50) CHECK (ownership_type IN ('owned', 'leased', 'rental')),
    lease_expiry DATE,

    -- Status
    status VARCHAR(50) DEFAULT 'available' CHECK (status IN ('available', 'in_use', 'maintenance', 'out_of_service', 'sold')),
    current_truck_id UUID REFERENCES trucks(id),
    current_location GEOGRAPHY(POINT),
    last_location_update TIMESTAMP,

    -- Maintenance
    last_inspection_date DATE,
    next_inspection_due DATE,

    -- Insurance & Registration
    registration_expiry DATE,
    insurance_expiry DATE,

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb

);

CREATE TABLE maintenance_records (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
asset_type VARCHAR(20) NOT NULL CHECK (asset_type IN ('truck', 'trailer')),
asset_id UUID NOT NULL, -- References trucks or trailers

    -- Maintenance Details
    maintenance_type VARCHAR(100) NOT NULL, -- 'oil_change', 'tire_rotation', 'brake_repair', etc
    description TEXT,
    service_date DATE NOT NULLCREATE TABLE maintenance_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_type VARCHAR(20) NOT NULL CHECK (asset_type IN ('truck', 'trailer')),
    asset_id UUID NOT NULL,

    maintenance_type VARCHAR(100) NOT NULL,
    description TEXT,
    service_date DATE NOT NULL,
    odometer_reading INTEGER,

    -- Cost
    labor_cost DECIMAL(10, 2),
    parts_cost DECIMAL(10, 2),
    total_cost DECIMAL(10, 2),

    -- Provider
    service_provider VARCHAR(255),
    mechanic_name VARCHAR(100),
    location VARCHAR(255),

    -- Status
    status VARCHAR(50) DEFAULT 'completed' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    performed_by UUID REFERENCES users(id)

);

-- ================================================================
-- CUSTOMER & SHIPPER MANAGEMENT
-- ================================================================

CREATE TABLE customers (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
company_id UUID REFERENCES companies(id) ON DELETE CASCADE,

    -- Company Information
    customer_name VARCHAR(255) NOT NULL,
    dba_name VARCHAR(255),
    customer_type VARCHAR(50) CHECK (customer_type IN ('shipper', 'broker', 'freight_forwarder', '3pl', 'manufacturer', 'distributor', 'retailer')),

    -- Contact
    email VARCHAR(255),
    phone VARCHAR(50),
    fax VARCHAR(50),
    website VARCHAR(255),

    -- Primary Contact Person
    contact_first_name VARCHAR(100),
    contact_last_name VARCHAR(100),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),

    -- Billing Address
    billing_address_line1 VARCHAR(255),
    billing_address_line2 VARCHAR(255),
    billing_city VARCHAR(100),
    billing_state VARCHAR(50),
    billing_zip VARCHAR(20),
    billing_country VARCHAR(3) DEFAULT 'USA',

    -- Payment Terms
    payment_terms INTEGER DEFAULT 30,
    credit_limit DECIMAL(15, 2),
    credit_status VARCHAR(50) CHECK (credit_status IN ('good', 'hold', 'collections', 'prepay_only')),

    -- Rates & Pricing
    default_rate_per_mile DECIMAL(10, 4),
    fuel_surcharge_percentage DECIMAL(5, 2),

    -- Status
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb

);

CREATE TABLE customer_locations (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,

    -- Location Details
    location_name VARCHAR(255) NOT NULL,
    location_type VARCHAR(50) CHECK (location_type IN ('pickup', 'delivery', 'both', 'warehouse', 'distribution_center')),

    -- Address
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(20) NOT NULL,
    country VARCHAR(3) DEFAULT 'USA',
    coordinates GEOGRAPHY(POINT),

    -- Contact
    contact_name VARCHAR(100),
    contact_phone VARCHAR(50),
    contact_email VARCHAR(255),

    -- Operating Hours
    operating_hours JSONB, -- {"monday": {"open": "08:00", "close": "17:00"}, ...}
    special_instructions TEXT,

    -- Appointment Required
    requires_appointment BOOLEAN DEFAULT FALSE,
    dock_count INTEGER,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()

);

-- ================================================================
-- CARRIER & BROKER NETWORK
-- ================================================================

CREATE TABLE carriers (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Company Information
    carrier_name VARCHAR(255) NOT NULL,
    mc_number VARCHAR(50) UNIQUE NOT NULL,
    dot_number VARCHAR(50) UNIQUE NOT NULL,
    scac_code VARCHAR(4),

    -- Contact
    email VARCHAR(255),
    phone VARCHAR(50),

    -- Address
    address_line1 VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(50),
    zip_code VARCHAR(20),

    -- Carrier Details
    carrier_type VARCHAR(50) CHECK (carrier_type IN ('asset_based', 'non_asset_based', 'freight_forwarder', 'owner_operator')),
    equipment_types TEXT[], -- ['dry_van', 'reefer', 'flatbed']
    service_areas TEXT[], -- ['nationwide', 'regional', 'local']

    -- Insurance
    insurance_provider VARCHAR(255),
    cargo_insurance_amount DECIMAL(15, 2),
    liability_insurance_amount DECIMAL(15, 2),
    insurance_expiry DATE,

    -- Performance & Rating
    safety_rating VARCHAR(20) CHECK (safety_rating IN ('satisfactory', 'conditional', 'unsatisfactory', 'not_rated')),
    on_time_percentage DECIMAL(5, 2),
    carrier_score DECIMAL(5, 2),
    total_loads_hauled INTEGER DEFAULT 0,

    -- Status
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'blacklisted', 'pending_approval')),
    approved_at TIMESTAMP,
    approved_by UUID REFERENCES users(id),

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb

);

CREATE TABLE carrier_rates (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
carrier_id UUID REFERENCES carriers(id) ON DELETE CASCADE,

    -- Rate Details
    origin_city VARCHAR(100),
    origin_state VARCHAR(50),
    destination_city VARCHAR(100),
    destination_state VARCHAR(50),

    -- Lane Information
    lane_type VARCHAR(50) CHECK (lane_type IN ('city_to_city', 'state_to_state', 'regional', 'nationwide')),
    equipment_type VARCHAR(50),

    -- Pricing
    rate_per_mile DECIMAL(10, 4),
    minimum_rate DECIMAL(10, 2),
    flat_rate DECIMAL(10, 2),

    -- Fuel Surcharge
    fuel_surcharge_type VARCHAR(50) CHECK (fuel_surcharge_type IN ('percentage', 'per_mile', 'flat')),
    fuel_surcharge_value DECIMAL(10, 4),

    -- Validity
    effective_date DATE NOT NULL,
    expiry_date DATE,

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()

);

-- ================================================================
-- LOAD & ORDER MANAGEMENT
-- ================================================================

CREATE TABLE loads (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
company_id UUID REFERENCES companies(id) ON DELETE CASCADE,

    -- Load Identification
    load_number VARCHAR(50) UNIQUE NOT NULL,
    reference_number VARCHAR(100), -- Customer reference
    bol_number VARCHAR(100), -- Bill of Lading

    -- Load Type
    load_type VARCHAR(50) CHECK (load_type IN ('ftl', 'ltl', 'partial', 'intermodal', 'expedited', 'team')),
    mode VARCHAR(50) CHECK (mode IN ('truckload', 'ltl', 'rail', 'air', 'ocean', 'intermodal')),

    -- Customer
    customer_id UUID REFERENCES customers(id),

    -- Carrier Assignment (for brokered loads)
    carrier_id UUID REFERENCES carriers(id),

    -- Internal Assets (for carrier-owned operations)
    truck_id UUID REFERENCES trucks(id),
    trailer_id UUID REFERENCES trailers(id),
    driver_id UUID REFERENCES drivers(id),

    -- Equipment Requirements
    equipment_type VARCHAR(50),
    equipment_length_feet DECIMAL(5, 2),
    requires_team BOOLEAN DEFAULT FALSE,
    requires_hazmat BOOLEAN DEFAULT FALSE,
    requires_temp_control BOOLEAN DEFAULT FALSE,
    temp_range_min DECIMAL(5, 2),
    temp_range_max DECIMAL(5, 2),

    -- Weight & Dimensions
    total_weight_lbs INTEGER,
    total_pieces INTEGER,
    commodity_description TEXT,
    special_instructions TEXT,

    -- Status & Tracking
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN (
        'pending', 'quoted', 'booked', 'dispatched', 'in_transit',
        'at_pickup', 'picked_up', 'at_delivery', 'delivered',
        'completed', 'cancelled', 'problem'
    )),

    -- Important Dates
    created_date TIMESTAMP DEFAULT NOW(),
    pickup_date DATE NOT NULL,
    pickup_time_start TIME,
    pickup_time_end TIME,
    delivery_date DATE NOT NULL,
    delivery_time_start TIME,
    delivery_time_end TIME,
    actual_pickup_time TIMESTAMP,
    actual_delivery_time TIMESTAMP,

    -- Financial
    customer_rate DECIMAL(10, 2),
    carrier_rate DECIMAL(10, 2), -- What we pay carrier (if brokered)
    fuel_surcharge DECIMAL(10, 2),
    accessorial_charges DECIMAL(10, 2),
    total_revenue DECIMAL(10, 2),
    total_cost DECIMAL(10, 2),
    profit_margin DECIMAL(10, 2),

    -- Miles
    total_miles INTEGER,
    loaded_miles INTEGER,
    empty_miles INTEGER,

    -- Documents
    rate_confirmation_url TEXT,
    bol_url TEXT,
    pod_url TEXT, -- Proof of Delivery

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    metadata JSONB DEFAULT '{}'::jsonb

);

CREATE TABLE load_stops (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
load_id UUID REFERENCES loads(id) ON DELETE CASCADE,

    -- Stop Information
    stop_sequence INTEGER NOT NULL,
    stop_type VARCHAR(50) NOT NULL CHECK (stop_type IN ('pickup', 'delivery', 'fuel', 'rest')),

    -- Location
    customer_location_id UUID REFERENCES customer_locations(id),
    location_name VARCHAR(255),
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(20) NOT NULL,
    coordinates GEOGRAPHY(POINT),

    -- Contact
    contact_name VARCHAR(100),
    contact_phone VARCHAR(50),

    -- Timing
    scheduled_date DATE NOT NULL,
    scheduled_time_start TIME,
    scheduled_time_end TIME,
    appointment_number VARCHAR(100),
    actual_arrival_time TIMESTAMP,
    actual_departure_time TIMESTAMP,

    -- Cargo Details
    pieces INTEGER,
    weight_lbs INTEGER,
    commodity TEXT,
    reference_numbers TEXT[], -- PO numbers, etc

    -- Status
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'arrived', 'loading', 'completed', 'departed')),
    special_instructions TEXT,

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()

);

CREATE TABLE load_documents (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
load_id UUID REFERENCES loads(id) ON DELETE CASCADE,

    -- Document Details
    document_type VARCHAR(100) NOT NULL, -- 'rate_con', 'bol', 'pod', 'invoice', 'lumper_receipt', etc
    file_url TEXT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),

    -- Metadata
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT NOW(),
    description TEXT

);

CREATE TABLE load_tracking (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
load_id UUID REFERENCES loads(id) ON DELETE CASCADE,

    -- Location Data
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location GEOGRAPHY(POINT),

    -- Status
    status_update VARCHAR(255),
    event_type VARCHAR(100), -- 'location_update', 'status_change', 'eld_update'

    -- Additional Data
    speed_mph DECIMAL(5, 2),
    heading DECIMAL(5, 2),
    odometer INTEGER,

    -- Source
    source VARCHAR(50) CHECK (source IN ('gps', 'eld', 'driver_app', 'manual', 'edi')),

    -- Timestamp
    tracked_at TIMESTAMP DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb

);

CREATE TABLE load_status_history (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
load_id UUID REFERENCES loads(id) ON DELETE CASCADE,

    -- Status Change
    old_status VARCHAR(50),
    new_status VARCHAR(50) NOT NULL,

    -- Details
    notes TEXT,
    changed_by UUID REFERENCES users(id),
    changed_at TIMESTAMP DEFAULT NOW(),

    -- Location at time of change
    location GEOGRAPHY(POINT)

);

-- ================================================================
-- INVOICING & ACCOUNTING
-- ================================================================

CREATE TABLE invoices (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
company_id UUID REFERENCES companies(id) ON DELETE CASCADE,

    -- Invoice Details
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    invoice_type VARCHAR(50) CHECK (invoice_type IN ('customer', 'carrier', 'vendor')),

    -- Related Entities
    customer_id UUID REFERENCES customers(id),
    carrier_id UUID REFERENCES carriers(id),
    load_id UUID REFERENCES loads(id),

    -- Financial
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    amount_paid DECIMAL(10, 2) DEFAULT 0,
    balance_due DECIMAL(10, 2) NOT NULL,

    -- Dates
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    paid_date DATE,

    -- Status
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'viewed', 'partial', 'paid', 'overdue', 'cancelled', 'disputed')),

    -- Payment
    payment_method VARCHAR(50) CHECK (payment_method IN ('check', 'ach', 'wire', 'credit_card', 'factoring', 'quickpay')),
    payment_reference VARCHAR(100),

    -- Factoring
    is_factored BOOLEAN DEFAULT FALSE,
    factoring_company VARCHAR(255),
    factoring_date DATE,
    factoring_fee DECIMAL(10, 2),

    -- Documents
    pdf_url TEXT,

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    sent_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb

);

CREATE TABLE invoice_line_items (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE,

    -- Line Item Details
    line_number INTEGER NOT NULL,
    description TEXT NOT NULL,
    item_type VARCHAR(100), -- 'linehaul', 'fuel_surcharge', 'detention', 'lumper', etc

    -- Pricing
    quantity DECIMAL(10, 2) DEFAULT 1,
    unit_price DECIMAL(10, 4) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,

    -- Tax
    is_taxable BOOLEAN DEFAULT FALSE,
    tax_rate DECIMAL(5, 4),

    -- System
    created_at TIMESTAMP DEFAULT NOW()

);

CREATE TABLE payments (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
company_id UUID REFERENCES companies(id) ON DELETE CASCADE,

    -- Payment Details
    payment_number VARCHAR(50) UNIQUE NOT NULL,
    payment_type VARCHAR(50) CHECK (payment_type IN ('received', 'sent')),

    -- Related Entities
    invoice_id UUID REFERENCES invoices(id),
    customer_id UUID REFERENCES customers(id),
    carrier_id UUID REFERENCES carriers(id),

    -- Amount
    amount DECIMAL(10, 2) NOT NULL,

    -- Method
    payment_method VARCHAR(50) CHECK (payment_method IN ('check', 'ach', 'wire', 'credit_card', 'cash', 'factoring')),
    check_number VARCHAR(50),
    transaction_id VARCHAR(100),

    -- Dates
    payment_date DATE NOT NULL,
    deposit_date DATE,

    -- Status
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'cleared', 'bounced', 'cancelled')),

    -- Bank Account
    bank_account VARCHAR(100),

    -- Notes
    notes TEXT,

    -- System
    created_at TIMESTAMP DEFAULT NOW(),
    created_by UUID REFERENCES users(id)

);

CREATE TABLE driver_settlements (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,

    -- Settlement Period
    settlement_number VARCHAR(50) UNIQUE NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,

    -- Gross Pay
    total_miles INTEGER DEFAULT 0,
    loaded_miles INTEGER DEFAULT 0,
    mileage_pay DECIMAL(10, 2) DEFAULT 0,
    load_pay DECIMAL(10, 2) DEFAULT 0,
    bonus_pay DECIMAL(10, 2) DEFAULT 0,
    other_pay DECIMAL(10, 2) DEFAULT 0,
    gross_pay DECIMAL(10, 2) NOT NULL,

    -- Deductions
    fuel_deductions DECIMAL(10, 2) DEFAULT 0,
    truck_payment DECIMAL(10, 2

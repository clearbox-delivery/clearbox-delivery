-- Initial schema for ClearBox Delivery
-- [REQ-CUST-ORDER-001, REQ-MER-CO-001, REQ-COU-MATCH-003, REQ-CORE-AUDIT-001]

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Order status enum
CREATE TYPE order_status AS ENUM (
  'PENDING_STORE_CONFIRM',
  'WAITING_COURIER',
  'COURIER_ASSIGNED',
  'PICKED_UP',
  'DELIVERING',
  'DELIVERED',
  'CANCELLED_CUSTOMER',
  'CANCELLED_MERCHANT',
  'CANCELLED_COURIER',
  'EXPIRED_UNMATCHED'
);

-- Actor type enum for audit trail
CREATE TYPE actor_type AS ENUM (
  'CUSTOMER',
  'MERCHANT',
  'COURIER',
  'SYSTEM'
);

-- Event type enum
CREATE TYPE event_type AS ENUM (
  'ORDER_CREATED',
  'MERCHANT_CONFIRMED',
  'COURIER_ACCEPTED',
  'COURIER_ARRIVED',
  'ORDER_PICKED_UP',
  'ORDER_DELIVERED',
  'ORDER_CANCELLED',
  'PREP_TIME_EXTENDED'
);

-- Merchants table
CREATE TABLE merchants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  google_maps_url TEXT,
  h3_cell TEXT NOT NULL, -- H3 resolution 10
  menu JSONB DEFAULT '[]'::jsonb,
  prep_time_minutes INT DEFAULT 15,
  is_open BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Couriers table
CREATE TABLE couriers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  current_h3_cell TEXT, -- Updated in real-time
  is_online BOOLEAN DEFAULT false,
  phone_number TEXT,
  rating NUMERIC(3, 2) DEFAULT 5.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customers table
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone_number TEXT,
  default_address TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Orders table
-- [REQ-CUST-ORDER-001] delivery_price_user_set is immutable
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES auth.users(id) NOT NULL,
  merchant_id UUID REFERENCES auth.users(id) NOT NULL,
  courier_id UUID REFERENCES auth.users(id),
  status order_status NOT NULL DEFAULT 'PENDING_STORE_CONFIRM',
  
  -- User-set delivery price [REQ-CUST-ORDER-001]
  delivery_price_user_set NUMERIC(10, 2) NOT NULL CHECK (delivery_price_user_set >= 30 AND delivery_price_user_set <= 5000),
  
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  h3_merchant TEXT,
  h3_customer TEXT,
  prep_time_minutes INT,
  customer_notes TEXT,
  merchant_notes TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure courier can only be assigned once
  CONSTRAINT unique_courier_assignment UNIQUE (id, courier_id)
);

-- Order events table for audit trail
-- [REQ-CORE-AUDIT-001]
CREATE TABLE order_events (
  id BIGSERIAL PRIMARY KEY,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE NOT NULL,
  actor_id UUID REFERENCES auth.users(id),
  actor_type actor_type NOT NULL,
  from_status order_status,
  to_status order_status NOT NULL,
  event_type event_type NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User devices table for device fingerprinting
-- [REQ-AUTH-OTP-001, REQ-AUTH-OTP-002]
CREATE TABLE user_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  first_seen_at TIMESTAMPTZ DEFAULT NOW(),
  last_seen_at TIMESTAMPTZ DEFAULT NOW(),
  is_blocked BOOLEAN DEFAULT false,
  UNIQUE(device_id)
);

-- OTP rate limits table
CREATE TABLE otp_rate_limits (
  id BIGSERIAL PRIMARY KEY,
  identifier TEXT NOT NULL, -- device_id or email/phone
  attempt_count INT DEFAULT 0,
  last_attempt_at TIMESTAMPTZ,
  lock_until TIMESTAMPTZ,
  UNIQUE(identifier)
);

-- Indexes for performance
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_merchant_id ON orders(merchant_id);
CREATE INDEX idx_orders_courier_id ON orders(courier_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_h3_merchant ON orders(h3_merchant);
CREATE INDEX idx_order_events_order_id ON order_events(order_id);
CREATE INDEX idx_order_events_created_at ON order_events(created_at);

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_merchants_updated_at BEFORE UPDATE ON merchants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_couriers_updated_at BEFORE UPDATE ON couriers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();



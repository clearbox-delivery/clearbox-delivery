-- Base seed data for testing
-- Creates test users, merchants, and sample data

-- Note: In production Supabase, users are created via auth.users
-- This is a simplified version for local testing

-- Insert test users (using service role)
-- Password for all: 'testpass123'
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'customer@test.com', 
   crypt('testpass123', gen_salt('bf')), NOW(), NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000002', 'merchant@test.com',
   crypt('testpass123', gen_salt('bf')), NOW(), NOW(), NOW()),
  ('00000000-0000-0000-0000-000000000003', 'courier@test.com',
   crypt('testpass123', gen_salt('bf')), NOW(), NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Insert customers
INSERT INTO customers (id, user_id, name, phone_number)
VALUES
  ('10000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000001',
   'Test Customer', '+886912345678')
ON CONFLICT (id) DO NOTHING;

-- Insert merchants
INSERT INTO merchants (id, user_id, name, address, h3_cell, menu, prep_time_minutes)
VALUES
  ('20000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002',
   '测试便当店',
   '台北市信义区信义路五段7号',
   '8a1234567890abc',
   '[
     {"sku": "bento-001", "name": "招牌便当", "price": 100, "volume_level": "V2", "weight_level": "W2"},
     {"sku": "bento-002", "name": "素食便当", "price": 90, "volume_level": "V2", "weight_level": "W1"},
     {"sku": "drink-001", "name": "红茶", "price": 20, "volume_level": "V1", "weight_level": "W1"}
   ]'::jsonb,
   15)
ON CONFLICT (id) DO NOTHING;

-- Insert couriers
INSERT INTO couriers (id, user_id, name, current_h3_cell, is_online, rating)
VALUES
  ('30000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000003',
   'Test Courier',
   '8a1234567890abc',
   true,
   5.00)
ON CONFLICT (id) DO NOTHING;

-- Insert sample order for testing
INSERT INTO orders (
  id,
  customer_id,
  merchant_id,
  delivery_price_user_set,
  items,
  h3_merchant,
  h3_customer,
  status
) VALUES (
  '40000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  45.00,
  '[{"sku": "bento-001", "name": "招牌便当", "quantity": 1, "unit_price": 100}]'::jsonb,
  '8a1234567890abc',
  '8a1234567890def',
  'PENDING_STORE_CONFIRM'
) ON CONFLICT (id) DO NOTHING;

-- Insert corresponding event
INSERT INTO order_events (
  order_id,
  actor_id,
  actor_type,
  to_status,
  event_type
) VALUES (
  '40000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'CUSTOMER',
  'PENDING_STORE_CONFIRM',
  'ORDER_CREATED'
) ON CONFLICT DO NOTHING;



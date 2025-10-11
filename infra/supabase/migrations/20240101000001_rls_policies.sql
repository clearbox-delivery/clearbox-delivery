-- Row Level Security Policies
-- [REQ-RLS-ISO-001] Data isolation by role

-- Enable RLS on all tables
ALTER TABLE merchants ENABLE ROW LEVEL SECURITY;
ALTER TABLE couriers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- Merchants policies
CREATE POLICY "Merchants can view own data"
  ON merchants FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Merchants can update own data"
  ON merchants FOR UPDATE
  USING (user_id = auth.uid());

-- Couriers policies
CREATE POLICY "Couriers can view own data"
  ON couriers FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Couriers can update own data"
  ON couriers FOR UPDATE
  USING (user_id = auth.uid());

-- Customers policies
CREATE POLICY "Customers can view own data"
  ON customers FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Customers can update own data"
  ON customers FOR UPDATE
  USING (user_id = auth.uid());

-- Orders policies
-- [TC-RLS-001] Customers only see own orders
CREATE POLICY "Customers can view own orders"
  ON orders FOR SELECT
  USING (customer_id = auth.uid());

CREATE POLICY "Customers can create orders"
  ON orders FOR INSERT
  WITH CHECK (customer_id = auth.uid());

-- Merchants can see orders for their store
CREATE POLICY "Merchants can view own orders"
  ON orders FOR SELECT
  USING (merchant_id = auth.uid());

CREATE POLICY "Merchants can update own orders"
  ON orders FOR UPDATE
  USING (merchant_id = auth.uid());

-- Couriers can see assigned orders or available orders
CREATE POLICY "Couriers can view assigned or available orders"
  ON orders FOR SELECT
  USING (
    courier_id = auth.uid() OR
    (status = 'WAITING_COURIER' AND courier_id IS NULL)
  );

CREATE POLICY "Couriers can update assigned orders"
  ON orders FOR UPDATE
  USING (courier_id = auth.uid());

-- Order events policies
CREATE POLICY "Users can view events for their orders"
  ON order_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_events.order_id
      AND (
        orders.customer_id = auth.uid() OR
        orders.merchant_id = auth.uid() OR
        orders.courier_id = auth.uid()
      )
    )
  );

CREATE POLICY "System can insert order events"
  ON order_events FOR INSERT
  WITH CHECK (true); -- Controlled via RPC functions

-- User devices policies
CREATE POLICY "Users can view own devices"
  ON user_devices FOR SELECT
  USING (user_id = auth.uid());



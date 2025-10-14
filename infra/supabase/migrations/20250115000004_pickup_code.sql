-- Pickup code for order verification
-- [REQ-COU-VERIF-002] Pickup code backend integration

-- Add pickup_code to orders table
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS pickup_code TEXT;

COMMENT ON COLUMN orders.pickup_code IS 'Six-digit pickup code for merchant verification. Generated when order is confirmed by merchant.';

-- Index for faster verification lookup
CREATE INDEX IF NOT EXISTS idx_orders_pickup_code ON orders(pickup_code) WHERE pickup_code IS NOT NULL;

-- RPC: Verify pickup code
-- [TC-COU-VERIF-007] Pickup code verification RPC
CREATE OR REPLACE FUNCTION verify_pickup_code(
  p_order_id UUID,
  p_code TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_stored_code TEXT;
BEGIN
  -- Get the stored pickup code for this order
  SELECT pickup_code INTO v_stored_code
  FROM orders
  WHERE id = p_order_id;

  -- Return true if codes match, false otherwise
  RETURN v_stored_code IS NOT NULL AND v_stored_code = p_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION verify_pickup_code IS 'Verify pickup code for order. Returns true if code matches, false otherwise.';

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION verify_pickup_code(UUID, TEXT) TO authenticated;

-- TODO: Update merchant_confirm RPC to generate pickup_code
-- Example logic for pickup code generation:
-- UPDATE orders 
-- SET pickup_code = LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0')
-- WHERE id = p_order_id AND status = 'CONFIRMED';
--
-- Or use a dedicated function:
-- CREATE OR REPLACE FUNCTION generate_pickup_code() RETURNS TEXT AS $$
-- BEGIN
--   RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
-- END;
-- $$ LANGUAGE plpgsql;


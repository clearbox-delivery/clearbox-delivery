-- Regenerate Pickup Code RPC
-- [REQ-COU-VERIF-004] Allow merchant to regenerate pickup code
-- [merchant_app_whitepaper.md Section 4.1]

CREATE OR REPLACE FUNCTION regenerate_pickup_code(p_order_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_new_code TEXT;
BEGIN
  -- Verify merchant owns this order and order is in valid status
  IF NOT EXISTS (
    SELECT 1 FROM orders
    WHERE id = p_order_id
    AND merchant_id = auth.uid()
    AND status IN ('PENDING_COURIER', 'WAITING_PICKUP')
  ) THEN
    RAISE EXCEPTION 'Order not found, unauthorized, or invalid status';
  END IF;

  -- Generate new 6-digit pickup code
  v_new_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

  -- Update order with new code
  UPDATE orders
  SET pickup_code = v_new_code,
      updated_at = NOW()
  WHERE id = p_order_id;

  -- Log event
  INSERT INTO order_events (order_id, event_type, actor_type, actor_id, metadata)
  VALUES (
    p_order_id,
    'PICKUP_CODE_REGENERATED',
    'MERCHANT',
    auth.uid(),
    jsonb_build_object('new_code', v_new_code)
  );

  RETURN v_new_code;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION regenerate_pickup_code(UUID) TO authenticated;

COMMENT ON FUNCTION regenerate_pickup_code IS 'Regenerate pickup code for an order (merchant only)';


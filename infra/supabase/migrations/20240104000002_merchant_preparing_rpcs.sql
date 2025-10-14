-- Merchant Preparing RPCs (備餐中狀態)
-- [merchant_app_whitepaper.md Section 4.3]
-- [REQ-MER-CO-003]

-- Merchant marks prep ready (我備好囉)
CREATE OR REPLACE FUNCTION merchant_prep_ready(
  p_order_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verify merchant owns this order and it's in COURIER_ASSIGNED status
  IF NOT EXISTS (
    SELECT 1 FROM orders 
    WHERE id = p_order_id 
    AND merchant_id = auth.uid()
    AND status = 'COURIER_ASSIGNED'
  ) THEN
    RAISE EXCEPTION 'Order not found or unauthorized';
  END IF;

  -- Update order status to PREP_READY (待取餐)
  UPDATE orders
  SET 
    status = 'PICKED_UP', -- Using PICKED_UP as prep ready state
    updated_at = NOW()
  WHERE id = p_order_id;

  -- Write event to timeline
  INSERT INTO order_events (order_id, event_type, actor_type, actor_id, metadata)
  VALUES (
    p_order_id,
    'MERCHANT_PREP_READY',
    'MERCHANT',
    auth.uid(),
    jsonb_build_object('ready_at', NOW())
  );
END;
$$;

-- Merchant extends prep time (+5 or +10 minutes)
CREATE OR REPLACE FUNCTION merchant_extend_prep_time(
  p_order_id UUID,
  p_plus_minutes INT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_prep_time INT;
  v_new_prep_time INT;
BEGIN
  -- Verify merchant owns this order and it's in COURIER_ASSIGNED status
  SELECT prep_time_minutes INTO v_current_prep_time
  FROM orders 
  WHERE id = p_order_id 
    AND merchant_id = auth.uid()
    AND status = 'COURIER_ASSIGNED';
    
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found or unauthorized';
  END IF;

  -- Calculate new prep time with upper bound (max 90 minutes)
  v_new_prep_time := LEAST(90, COALESCE(v_current_prep_time, 15) + p_plus_minutes);

  -- Update prep time
  UPDATE orders
  SET 
    prep_time_minutes = v_new_prep_time,
    updated_at = NOW()
  WHERE id = p_order_id;

  -- Write event to timeline
  INSERT INTO order_events (order_id, event_type, actor_type, actor_id, metadata)
  VALUES (
    p_order_id,
    'MERCHANT_EXTEND_PREP',
    'MERCHANT',
    auth.uid(),
    jsonb_build_object(
      'plus_minutes', p_plus_minutes,
      'new_prep_time', v_new_prep_time
    )
  );
END;
$$;


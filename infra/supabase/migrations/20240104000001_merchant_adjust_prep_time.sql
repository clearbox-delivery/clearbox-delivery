-- Merchant Adjust Prep Time RPC
-- [merchant_app_whitepaper.md Section 4.2]
-- [REQ-MER-CO-002]

CREATE OR REPLACE FUNCTION merchant_adjust_prep_time(
  p_order_id UUID,
  p_delta_minutes INT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_prep_time INT;
  v_new_prep_time INT;
BEGIN
  -- Verify merchant owns this order and it's in WAITING_COURIER status
  SELECT prep_time_minutes INTO v_current_prep_time
  FROM orders 
  WHERE id = p_order_id 
    AND merchant_id = auth.uid()
    AND status = 'WAITING_COURIER';
    
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found or unauthorized';
  END IF;

  -- Calculate new prep time with bounds (5-60 minutes)
  v_new_prep_time := GREATEST(5, LEAST(60, COALESCE(v_current_prep_time, 15) + p_delta_minutes));

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
    'MERCHANT_ADJUST_PREP_TIME',
    'MERCHANT',
    auth.uid(),
    jsonb_build_object(
      'delta_minutes', p_delta_minutes,
      'new_prep_time', v_new_prep_time
    )
  );
END;
$$;


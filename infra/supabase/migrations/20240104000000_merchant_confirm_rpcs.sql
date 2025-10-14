-- Merchant Confirm and Cancel RPCs
-- [merchant_app_whitepaper.md Section 4.1]
-- [REQ-MER-CO-001]

-- Merchant confirm order (4-step flow: stock, volume, prep time, notes)
CREATE OR REPLACE FUNCTION merchant_confirm(
  p_order_id UUID,
  p_stock_ok BOOLEAN,
  p_volume_ok BOOLEAN,
  p_prep_minutes INT,
  p_note TEXT
)
RETURNS orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order orders;
BEGIN
  -- Verify merchant owns this order
  IF NOT EXISTS (
    SELECT 1 FROM orders
    WHERE id = p_order_id
    AND merchant_id = auth.uid()
    AND status = 'PENDING_CONFIRM'
  ) THEN
    RAISE EXCEPTION 'Order not found or unauthorized';
  END IF;

  -- Update order status and prep time
  UPDATE orders
  SET
    status = 'PENDING_COURIER',
    prep_time_minutes = p_prep_minutes,
    merchant_notes = p_note,
    updated_at = NOW()
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  -- Generate 6-digit pickup code (only if not already set)
  -- [REQ-COU-VERIF-003] Auto-generate pickup code on first confirm
  UPDATE orders
  SET pickup_code = LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0')
  WHERE id = p_order_id
    AND pickup_code IS NULL;

  -- Write event to timeline
  INSERT INTO order_events (order_id, event_type, actor_type, actor_id, metadata)
  VALUES (
    p_order_id,
    'MERCHANT_CONFIRMED',
    'MERCHANT',
    auth.uid(),
    jsonb_build_object(
      'stock_ok', p_stock_ok,
      'volume_ok', p_volume_ok,
      'prep_minutes', p_prep_minutes,
      'note', p_note
    )
  );

  RETURN v_order;
END;
$$;

-- Merchant cancel order with reason
CREATE OR REPLACE FUNCTION merchant_cancel(
  p_order_id UUID,
  p_cancel_reason TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verify merchant owns this order
  IF NOT EXISTS (
    SELECT 1 FROM orders
    WHERE id = p_order_id
    AND merchant_id = auth.uid()
    AND status IN ('PENDING_CONFIRM', 'PENDING_COURIER')
  ) THEN
    RAISE EXCEPTION 'Order not found or unauthorized';
  END IF;

  -- Update order status
  UPDATE orders
  SET
    status = 'CANCELLED_BY_MERCHANT',
    updated_at = NOW()
  WHERE id = p_order_id;

  -- Write event to timeline
  INSERT INTO order_events (order_id, event_type, actor_type, actor_id, metadata)
  VALUES (
    p_order_id,
    'MERCHANT_CANCELLED',
    'MERCHANT',
    auth.uid(),
    jsonb_build_object('reason', p_cancel_reason)
  );
END;
$$;


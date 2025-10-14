-- Courier RPCs for atomic order operations
-- [REQ-COU-FLOW-007] Replace REST with RPCs for accept_order and mark_delivered

-- RPC: Accept order (with optimistic locking and conflict handling)
-- [TC-COU-ACPT-001] Accept order race condition handling
CREATE OR REPLACE FUNCTION accept_order(
  p_order_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_order RECORD;
  v_result JSONB;
BEGIN
  -- Atomic update with optimistic lock
  UPDATE orders
  SET
    status = 'COURIER_ASSIGNED',
    courier_id = auth.uid(),
    updated_at = NOW()
  WHERE id = p_order_id
    AND status = 'WAITING_COURIER'
    AND courier_id IS NULL -- Must not be assigned yet
  RETURNING * INTO v_order;

  -- Check if update succeeded
  IF NOT FOUND THEN
    -- Order already assigned or not in correct status
    SELECT
      jsonb_build_object(
        'success', false,
        'error_code', 'ERR_ALREADY_ASSIGNED',
        'message', 'Order has already been accepted by another courier or is not available'
      ) INTO v_result;
    RETURN v_result;
  END IF;

  -- Success
  SELECT
    jsonb_build_object(
      'success', true,
      'order', row_to_json(v_order)
    ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION accept_order IS 'Atomically accept order with conflict handling. Returns {success, order?, error_code?, message?}';

-- RPC: Mark order as delivered
-- [REQ-COU-FLOW-004] Complete delivery with validation
CREATE OR REPLACE FUNCTION mark_delivered(
  p_order_id UUID,
  p_delivery_photo_url TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_order RECORD;
  v_result JSONB;
BEGIN
  -- Update with validation
  UPDATE orders
  SET
    status = 'DELIVERED',
    updated_at = NOW()
    -- TODO: Add delivery_photo_url column if needed
  WHERE id = p_order_id
    AND courier_id = auth.uid() -- Must be assigned to this courier
    AND status IN ('PICKED_UP', 'DELIVERING') -- Valid previous states
  RETURNING * INTO v_order;

  -- Check if update succeeded
  IF NOT FOUND THEN
    -- Order not found, not assigned to courier, or invalid status
    SELECT
      jsonb_build_object(
        'success', false,
        'error_code', 'ERR_INVALID_STATE',
        'message', 'Order cannot be marked as delivered (not assigned to you or invalid status)'
      ) INTO v_result;
    RETURN v_result;
  END IF;

  -- Success
  SELECT
    jsonb_build_object(
      'success', true,
      'order', row_to_json(v_order)
    ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION mark_delivered IS 'Mark order as delivered with courier validation. Returns {success, order?, error_code?, message?}';

-- Grant execute permissions to authenticated users
GRANT EXECUTE ON FUNCTION accept_order(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION mark_delivered(UUID, TEXT) TO authenticated;


-- RPC Functions for order lifecycle
-- [REQ-CUST-ORDER-001, REQ-MER-CO-001, REQ-COU-MATCH-003]

-- Create order function
-- [TC-CUST-001, TC-CUST-002]
CREATE OR REPLACE FUNCTION create_order(
  p_merchant_id UUID,
  p_items JSONB,
  p_delivery_price NUMERIC,
  p_h3_customer TEXT DEFAULT NULL,
  p_customer_notes TEXT DEFAULT NULL
)
RETURNS orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order orders;
BEGIN
  -- Validate price [REQ-CUST-ORDER-001]
  IF p_delivery_price < 30 OR p_delivery_price > 5000 THEN
    RAISE EXCEPTION 'ERR_PRICE_MIN: Delivery price must be between 30 and 5000'
      USING ERRCODE = '22000';
  END IF;

  -- Insert order
  INSERT INTO orders (
    customer_id,
    merchant_id,
    delivery_price_user_set,
    items,
    h3_customer,
    customer_notes,
    status
  ) VALUES (
    auth.uid(),
    p_merchant_id,
    p_delivery_price,
    p_items,
    p_h3_customer,
    p_customer_notes,
    'PENDING_STORE_CONFIRM'
  ) RETURNING * INTO v_order;

  -- Insert audit event [REQ-CORE-AUDIT-001]
  INSERT INTO order_events (
    order_id,
    actor_id,
    actor_type,
    to_status,
    event_type,
    metadata
  ) VALUES (
    v_order.id,
    auth.uid(),
    'CUSTOMER',
    'PENDING_STORE_CONFIRM',
    'ORDER_CREATED',
    jsonb_build_object('delivery_price', p_delivery_price)
  );

  RETURN v_order;
END;
$$;

-- Merchant confirm order function
-- [TC-MER-CO-001]
CREATE OR REPLACE FUNCTION merchant_confirm_order(
  p_order_id UUID,
  p_prep_time_minutes INT,
  p_merchant_notes TEXT DEFAULT NULL
)
RETURNS orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order orders;
  v_old_status order_status;
BEGIN
  -- Get current order
  SELECT * INTO v_order FROM orders WHERE id = p_order_id AND merchant_id = auth.uid();
  
  IF v_order IS NULL THEN
    RAISE EXCEPTION 'Order not found or unauthorized';
  END IF;

  IF v_order.status != 'PENDING_STORE_CONFIRM' THEN
    RAISE EXCEPTION 'Order is not in pending confirm status';
  END IF;

  v_old_status := v_order.status;

  -- Update order
  UPDATE orders
  SET
    status = 'WAITING_COURIER',
    prep_time_minutes = p_prep_time_minutes,
    merchant_notes = p_merchant_notes
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  -- Insert audit event [REQ-CORE-AUDIT-001]
  INSERT INTO order_events (
    order_id,
    actor_id,
    actor_type,
    from_status,
    to_status,
    event_type,
    metadata
  ) VALUES (
    v_order.id,
    auth.uid(),
    'MERCHANT',
    v_old_status,
    'WAITING_COURIER',
    'MERCHANT_CONFIRMED',
    jsonb_build_object('prep_time_minutes', p_prep_time_minutes)
  );

  RETURN v_order;
END;
$$;

-- Courier accept order function with atomic locking
-- [TC-COU-ACPT-001] Race condition handling
CREATE OR REPLACE FUNCTION accept_order(
  p_order_id UUID
)
RETURNS orders
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_order orders;
  v_old_status order_status;
  v_rows_affected INT;
BEGIN
  -- Atomic update with lock [REQ-COU-MATCH-003]
  UPDATE orders
  SET
    courier_id = auth.uid(),
    status = 'COURIER_ASSIGNED'
  WHERE
    id = p_order_id
    AND status = 'WAITING_COURIER'
    AND courier_id IS NULL
  RETURNING * INTO v_order;

  GET DIAGNOSTICS v_rows_affected = ROW_COUNT;

  IF v_rows_affected = 0 THEN
    -- Order already assigned or not available
    SELECT status INTO v_old_status FROM orders WHERE id = p_order_id;
    
    IF v_old_status != 'WAITING_COURIER' THEN
      RAISE EXCEPTION 'ERR_ALREADY_ASSIGNED: Order has already been accepted'
        USING ERRCODE = '23505'; -- unique_violation
    ELSE
      RAISE EXCEPTION 'Order not found';
    END IF;
  END IF;

  -- Insert audit event [REQ-CORE-AUDIT-001]
  INSERT INTO order_events (
    order_id,
    actor_id,
    actor_type,
    from_status,
    to_status,
    event_type
  ) VALUES (
    v_order.id,
    auth.uid(),
    'COURIER',
    'WAITING_COURIER',
    'COURIER_ASSIGNED',
    'COURIER_ACCEPTED'
  );

  RETURN v_order;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_order TO authenticated;
GRANT EXECUTE ON FUNCTION merchant_confirm_order TO authenticated;
GRANT EXECUTE ON FUNCTION accept_order TO authenticated;



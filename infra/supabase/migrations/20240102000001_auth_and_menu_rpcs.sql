-- RPC 函数：认证与菜单管理
-- [REQ-AUTH-OTP-001, REQ-AUTH-OTP-002, REQ-MER-MENU-001]

-- 发送 OTP [REQ-AUTH-OTP-001, REQ-AUTH-OTP-002]
CREATE OR REPLACE FUNCTION send_otp(
  p_identifier TEXT,
  p_otp_type TEXT,
  p_device_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rate_limit RECORD;
  v_otp_code TEXT;
  v_max_attempts INT;
  v_cooldown_seconds INT;
BEGIN
  -- 设定速率限制
  IF p_otp_type = 'EMAIL' THEN
    v_max_attempts := 20;
    v_cooldown_seconds := 30;
  ELSIF p_otp_type = 'PHONE' THEN
    v_max_attempts := 5;
    v_cooldown_seconds := 120;
  ELSE
    RAISE EXCEPTION 'Invalid OTP type';
  END IF;

  -- 检查速率限制
  SELECT * INTO v_rate_limit
  FROM otp_rate_limits
  WHERE identifier = p_device_id
  FOR UPDATE;

  IF v_rate_limit IS NOT NULL THEN
    -- 检查是否被锁定
    IF v_rate_limit.lock_until IS NOT NULL 
       AND v_rate_limit.lock_until > NOW() THEN
      RAISE EXCEPTION 'ERR_RATE_LIMIT: Device locked until %', v_rate_limit.lock_until;
    END IF;

    -- 检查尝试次数
    IF v_rate_limit.attempt_count >= v_max_attempts THEN
      UPDATE otp_rate_limits
      SET lock_until = NOW() + INTERVAL '24 hours'
      WHERE identifier = p_device_id;
      
      RAISE EXCEPTION 'ERR_MAX_ATTEMPTS: Maximum attempts exceeded';
    END IF;

    -- 检查冷却时间
    IF v_rate_limit.last_attempt_at IS NOT NULL
       AND v_rate_limit.last_attempt_at + (v_cooldown_seconds || ' seconds')::INTERVAL > NOW() THEN
      RAISE EXCEPTION 'ERR_COOLDOWN: Please wait % seconds', 
        v_cooldown_seconds - EXTRACT(EPOCH FROM (NOW() - v_rate_limit.last_attempt_at));
    END IF;

    -- 更新尝试计数
    UPDATE otp_rate_limits
    SET attempt_count = attempt_count + 1,
        last_attempt_at = NOW()
    WHERE identifier = p_device_id;
  ELSE
    -- 首次尝试
    INSERT INTO otp_rate_limits (identifier, attempt_count, last_attempt_at)
    VALUES (p_device_id, 1, NOW());
  END IF;

  -- 生成 6 位数 OTP
  v_otp_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');

  -- 删除旧的 OTP
  DELETE FROM otp_verifications
  WHERE identifier = p_identifier
    AND otp_type = p_otp_type
    AND device_id = p_device_id;

  -- 插入新 OTP
  INSERT INTO otp_verifications (
    identifier,
    otp_code,
    otp_type,
    device_id,
    expires_at
  ) VALUES (
    p_identifier,
    v_otp_code,
    p_otp_type,
    p_device_id,
    NOW() + INTERVAL '10 minutes'
  );

  -- TODO: 实际发送 OTP (Email/SMS)
  -- 开发环境返回 OTP，生产环境不返回
  RETURN jsonb_build_object(
    'success', true,
    'otp_code', v_otp_code, -- 仅开发环境
    'expires_in', 600
  );
END;
$$;

-- 验证 OTP
CREATE OR REPLACE FUNCTION verify_otp(
  p_identifier TEXT,
  p_otp_code TEXT,
  p_otp_type TEXT,
  p_device_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_otp RECORD;
BEGIN
  -- 查找 OTP
  SELECT * INTO v_otp
  FROM otp_verifications
  WHERE identifier = p_identifier
    AND otp_type = p_otp_type
    AND device_id = p_device_id
    AND verified = false
    AND expires_at > NOW()
  FOR UPDATE;

  IF v_otp IS NULL THEN
    RAISE EXCEPTION 'ERR_INVALID_OTP: OTP not found or expired';
  END IF;

  -- 增加尝试次数
  UPDATE otp_verifications
  SET attempts = attempts + 1
  WHERE id = v_otp.id;

  -- 检查尝试次数
  IF v_otp.attempts >= 3 THEN
    DELETE FROM otp_verifications WHERE id = v_otp.id;
    RAISE EXCEPTION 'ERR_MAX_ATTEMPTS: Too many attempts';
  END IF;

  -- 验证 OTP
  IF v_otp.otp_code != p_otp_code THEN
    RAISE EXCEPTION 'ERR_WRONG_OTP: Invalid OTP code';
  END IF;

  -- 标记为已验证
  UPDATE otp_verifications
  SET verified = true
  WHERE id = v_otp.id;

  RETURN jsonb_build_object(
    'success', true,
    'verified', true
  );
END;
$$;

-- 创建/更新用户配置
CREATE OR REPLACE FUNCTION upsert_user_profile(
  p_role TEXT,
  p_name TEXT,
  p_phone_number TEXT DEFAULT NULL
)
RETURNS user_profiles
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_profile user_profiles;
BEGIN
  INSERT INTO user_profiles (user_id, role, name, phone_number)
  VALUES (auth.uid(), p_role, p_name, p_phone_number)
  ON CONFLICT (user_id) DO UPDATE
  SET name = EXCLUDED.name,
      phone_number = EXCLUDED.phone_number,
      updated_at = NOW()
  RETURNING * INTO v_profile;

  RETURN v_profile;
END;
$$;

-- 菜单管理 RPC [REQ-MER-MENU-001]

-- 创建菜单项
CREATE OR REPLACE FUNCTION create_menu_item(
  p_category TEXT,
  p_name TEXT,
  p_description TEXT,
  p_price NUMERIC,
  p_image_url TEXT DEFAULT NULL,
  p_volume_level TEXT DEFAULT NULL,
  p_weight_level TEXT DEFAULT NULL,
  p_prep_time_minutes INT DEFAULT 15
)
RETURNS menu_items
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_item menu_items;
BEGIN
  INSERT INTO menu_items (
    merchant_id, category, name, description, price,
    image_url, volume_level, weight_level, prep_time_minutes
  ) VALUES (
    auth.uid(), p_category, p_name, p_description, p_price,
    p_image_url, p_volume_level, p_weight_level, p_prep_time_minutes
  ) RETURNING * INTO v_item;

  RETURN v_item;
END;
$$;

-- 更新菜单项
CREATE OR REPLACE FUNCTION update_menu_item(
  p_item_id UUID,
  p_name TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_price NUMERIC DEFAULT NULL,
  p_is_available BOOLEAN DEFAULT NULL
)
RETURNS menu_items
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_item menu_items;
BEGIN
  UPDATE menu_items
  SET
    name = COALESCE(p_name, name),
    description = COALESCE(p_description, description),
    price = COALESCE(p_price, price),
    is_available = COALESCE(p_is_available, is_available),
    updated_at = NOW()
  WHERE id = p_item_id
    AND merchant_id = auth.uid()
  RETURNING * INTO v_item;

  IF v_item IS NULL THEN
    RAISE EXCEPTION 'Menu item not found or unauthorized';
  END IF;

  RETURN v_item;
END;
$$;

-- 删除菜单项
CREATE OR REPLACE FUNCTION delete_menu_item(p_item_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM menu_items
  WHERE id = p_item_id
    AND merchant_id = auth.uid();

  RETURN FOUND;
END;
$$;

-- 更新外送员位置 [REQ-COU-HEAT-001]
CREATE OR REPLACE FUNCTION update_courier_location(
  p_h3_cell TEXT,
  p_latitude NUMERIC,
  p_longitude NUMERIC,
  p_is_online BOOLEAN
)
RETURNS courier_locations
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_location courier_locations;
BEGIN
  INSERT INTO courier_locations (
    courier_id, current_h3_cell, latitude, longitude, is_online
  ) VALUES (
    auth.uid(), p_h3_cell, p_latitude, p_longitude, p_is_online
  )
  ON CONFLICT (courier_id) DO UPDATE
  SET current_h3_cell = EXCLUDED.current_h3_cell,
      latitude = EXCLUDED.latitude,
      longitude = EXCLUDED.longitude,
      is_online = EXCLUDED.is_online,
      updated_at = NOW()
  RETURNING * INTO v_location;

  RETURN v_location;
END;
$$;

-- 计算 H3 热度 [REQ-COU-HEAT-001]
CREATE OR REPLACE FUNCTION calculate_h3_heat(p_h3_cells TEXT[])
RETURNS TABLE(h3_cell TEXT, heat_score NUMERIC)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    cell.h3_cell,
    CASE
      WHEN courier_count = 0 THEN order_count::NUMERIC
      ELSE order_count::NUMERIC / (1 + courier_count)
    END as heat_score
  FROM (
    SELECT unnest(p_h3_cells) as h3_cell
  ) cell
  LEFT JOIN (
    SELECT h3_merchant, COUNT(*) as order_count
    FROM orders
    WHERE status = 'WAITING_COURIER'
    GROUP BY h3_merchant
  ) orders ON cell.h3_cell = orders.h3_merchant
  LEFT JOIN (
    SELECT current_h3_cell, COUNT(*) as courier_count
    FROM courier_locations
    WHERE is_online = true
    GROUP BY current_h3_cell
  ) couriers ON cell.h3_cell = couriers.current_h3_cell;
END;
$$;

-- 授权
GRANT EXECUTE ON FUNCTION send_otp TO anon, authenticated;
GRANT EXECUTE ON FUNCTION verify_otp TO anon, authenticated;
GRANT EXECUTE ON FUNCTION upsert_user_profile TO authenticated;
GRANT EXECUTE ON FUNCTION create_menu_item TO authenticated;
GRANT EXECUTE ON FUNCTION update_menu_item TO authenticated;
GRANT EXECUTE ON FUNCTION delete_menu_item TO authenticated;
GRANT EXECUTE ON FUNCTION update_courier_location TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_h3_heat TO authenticated;


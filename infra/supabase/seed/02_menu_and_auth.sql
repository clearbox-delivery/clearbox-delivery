-- 菜单与认证种子数据

-- 用户配置
INSERT INTO user_profiles (user_id, role, name, phone_number, is_verified)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'CUSTOMER', '测试顾客', '+886912345678', true),
  ('00000000-0000-0000-0000-000000000002', 'MERCHANT', '测试便当店', '+886923456789', true),
  ('00000000-0000-0000-0000-000000000003', 'COURIER', '测试外送员', '+886934567890', true)
ON CONFLICT (user_id) DO NOTHING;

-- 菜单品项 [REQ-MER-MENU-001]
INSERT INTO menu_items (
  merchant_id, category, name, description, price,
  volume_level, weight_level, prep_time_minutes, is_available
) VALUES
  ('00000000-0000-0000-0000-000000000002', '便当类', '招牌便当', '经典口味，附配菜', 100, 'V2', 'W2', 15, true),
  ('00000000-0000-0000-0000-000000000002', '便当类', '素食便当', '健康蔬食', 90, 'V2', 'W1', 15, true),
  ('00000000-0000-0000-0000-000000000002', '饮料类', '红茶', '大杯冷饮', 20, 'V1', 'W1', 5, true),
  ('00000000-0000-0000-0000-000000000002', '饮料类', '珍珠奶茶', '招牌奶茶', 35, 'V1', 'W1', 5, true),
  ('00000000-0000-0000-0000-000000000002', '汤品类', '味噌汤', '热汤', 25, 'V1', 'W1', 10, true)
ON CONFLICT DO NOTHING;

-- 营业时间
INSERT INTO merchant_hours (merchant_id, day_of_week, open_time, close_time, is_closed)
VALUES
  ('00000000-0000-0000-0000-000000000002', 1, '11:00', '20:00', false), -- Monday
  ('00000000-0000-0000-0000-000000000002', 2, '11:00', '20:00', false), -- Tuesday
  ('00000000-0000-0000-0000-000000000002', 3, '11:00', '20:00', false), -- Wednesday
  ('00000000-0000-0000-0000-000000000002', 4, '11:00', '20:00', false), -- Thursday
  ('00000000-0000-0000-0000-000000000002', 5, '11:00', '20:00', false), -- Friday
  ('00000000-0000-0000-0000-000000000002', 6, '11:00', '15:00', false), -- Saturday
  ('00000000-0000-0000-0000-000000000002', 0, '00:00', '00:00', true)   -- Sunday (closed)
ON CONFLICT DO NOTHING;

-- 外送员位置 [REQ-COU-HEAT-001]
INSERT INTO courier_locations (courier_id, current_h3_cell, latitude, longitude, is_online)
VALUES
  ('00000000-0000-0000-0000-000000000003', '8a1234567890abc', 25.0340, 121.5645, true)
ON CONFLICT (courier_id) DO UPDATE
SET current_h3_cell = EXCLUDED.current_h3_cell,
    latitude = EXCLUDED.latitude,
    longitude = EXCLUDED.longitude,
    is_online = EXCLUDED.is_online,
    updated_at = NOW();


-- 认证与菜单管理扩展表
-- [REQ-AUTH-OTP-001, REQ-AUTH-OTP-002, REQ-MER-MENU-001]

-- OTP 验证记录表
CREATE TABLE IF NOT EXISTS otp_verifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  identifier TEXT NOT NULL, -- email or phone
  otp_code TEXT NOT NULL,
  otp_type TEXT NOT NULL CHECK (otp_type IN ('EMAIL', 'PHONE')),
  device_id TEXT NOT NULL,
  attempts INT DEFAULT 0,
  verified BOOLEAN DEFAULT false,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(identifier, otp_type, device_id)
);

-- 用户配置表
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('CUSTOMER', 'MERCHANT', 'COURIER')),
  name TEXT NOT NULL,
  phone_number TEXT,
  avatar_url TEXT,
  is_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 证件表 (商家/外送员)
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL CHECK (document_type IN (
    'ID_CARD', 'DRIVERS_LICENSE', 'VEHICLE_REGISTRATION',
    'POLICE_CLEARANCE', 'BANK_BOOK', 'BUSINESS_LICENSE',
    'FOOD_REGISTRATION', 'THERMAL_BAG_PHOTO'
  )),
  document_url TEXT NOT NULL,
  verification_status TEXT DEFAULT 'PENDING' CHECK (verification_status IN ('PENDING', 'APPROVED', 'REJECTED')),
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 菜单品项表 [REQ-MER-MENU-001]
CREATE TABLE IF NOT EXISTS menu_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  merchant_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
  image_url TEXT,
  volume_level TEXT CHECK (volume_level IN ('V1', 'V2', 'V3', 'V4')),
  weight_level TEXT CHECK (weight_level IN ('W1', 'W2', 'W3', 'W4')),
  prep_time_minutes INT DEFAULT 15,
  is_available BOOLEAN DEFAULT true,
  stock_quantity INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 商家营业时间表
CREATE TABLE IF NOT EXISTS merchant_hours (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  merchant_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday
  open_time TIME NOT NULL,
  close_time TIME NOT NULL,
  is_closed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 外送员当前位置表 (用于热度计算)
CREATE TABLE IF NOT EXISTS courier_locations (
  courier_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  current_h3_cell TEXT NOT NULL,
  latitude NUMERIC(10, 8),
  longitude NUMERIC(11, 8),
  is_online BOOLEAN DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_otp_verifications_identifier ON otp_verifications(identifier, otp_type);
CREATE INDEX idx_otp_verifications_expires ON otp_verifications(expires_at);
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_menu_items_merchant_id ON menu_items(merchant_id);
CREATE INDEX idx_menu_items_available ON menu_items(is_available);
CREATE INDEX idx_courier_locations_h3 ON courier_locations(current_h3_cell);
CREATE INDEX idx_courier_locations_online ON courier_locations(is_online);

-- RLS 启用
ALTER TABLE otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchant_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE courier_locations ENABLE ROW LEVEL SECURITY;

-- RLS 策略

-- user_profiles
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (user_id = auth.uid());

-- documents
CREATE POLICY "Users can view own documents"
  ON documents FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own documents"
  ON documents FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- menu_items [REQ-MER-MENU-001]
CREATE POLICY "Anyone can view available menu items"
  ON menu_items FOR SELECT
  USING (is_available = true);

CREATE POLICY "Merchants can manage own menu"
  ON menu_items FOR ALL
  USING (merchant_id = auth.uid());

-- merchant_hours
CREATE POLICY "Anyone can view merchant hours"
  ON merchant_hours FOR SELECT
  USING (true);

CREATE POLICY "Merchants can manage own hours"
  ON merchant_hours FOR ALL
  USING (merchant_id = auth.uid());

-- courier_locations [REQ-COU-HEAT-001]
CREATE POLICY "Couriers can update own location"
  ON courier_locations FOR ALL
  USING (courier_id = auth.uid());

CREATE POLICY "System can view online courier locations"
  ON courier_locations FOR SELECT
  USING (is_online = true);

-- Triggers
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON menu_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- Customer Profile and Addresses
-- [customer_app_whitepaper.md Section 2]
-- [REQ-CUST-PROFILE-001, REQ-CUST-ADDRESS-001]

-- Add columns to user_profiles
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS nickname TEXT,
  ADD COLUMN IF NOT EXISTS initial_setup_complete BOOLEAN DEFAULT FALSE;

-- Create user_addresses table
CREATE TABLE IF NOT EXISTS user_addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  google_maps_link TEXT DEFAULT '',
  latitude NUMERIC(10, 8) DEFAULT 25.0330,
  longitude NUMERIC(11, 8) DEFAULT 121.5654,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT user_addresses_name_check CHECK (char_length(name) > 0),
  CONSTRAINT user_addresses_address_check CHECK (char_length(address) > 0)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS user_addresses_user_id_idx ON user_addresses(user_id);
CREATE INDEX IF NOT EXISTS user_addresses_created_at_idx ON user_addresses(created_at DESC);

-- Enable RLS
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_addresses
-- Users can only see their own addresses
CREATE POLICY "Users can view own addresses"
  ON user_addresses FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own addresses
CREATE POLICY "Users can insert own addresses"
  ON user_addresses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own addresses
CREATE POLICY "Users can update own addresses"
  ON user_addresses FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own addresses
CREATE POLICY "Users can delete own addresses"
  ON user_addresses FOR DELETE
  USING (auth.uid() = user_id);

-- Update RLS for user_profiles (allow users to update their own nickname and setup status)
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);


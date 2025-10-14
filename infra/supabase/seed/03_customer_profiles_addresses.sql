-- Seed customer profiles and addresses (dev only)
-- [customer_app_whitepaper.md Section 2]

-- Update test customer profile with nickname
UPDATE user_profiles
SET 
  nickname = '測試顧客',
  initial_setup_complete = TRUE
WHERE role = 'CUSTOMER'
LIMIT 1;

-- Insert sample addresses (for first customer user)
INSERT INTO user_addresses (user_id, name, address, google_maps_link)
SELECT 
  id,
  '家',
  '台北市信義區信義路五段7號',
  'https://maps.google.com/?q=台北101'
FROM user_profiles
WHERE role = 'CUSTOMER'
LIMIT 1;

INSERT INTO user_addresses (user_id, name, address, google_maps_link)
SELECT 
  id,
  '公司',
  '台北市中正區重慶南路一段122號',
  ''
FROM user_profiles
WHERE role = 'CUSTOMER'
LIMIT 1;


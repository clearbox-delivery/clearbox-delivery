-- Add weekly_meal_count and coordinates to merchants for S sorting
-- [customer_app_whitepaper.md Section 4.4]
-- [docs/PHASE2_DATA_SOURCES.md] Temporary column for MVP

ALTER TABLE merchants 
  ADD COLUMN IF NOT EXISTS weekly_meal_count INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS latitude NUMERIC(10, 8),
  ADD COLUMN IF NOT EXISTS longitude NUMERIC(11, 8);

-- Update existing merchants with sample data (dev)
UPDATE merchants SET weekly_meal_count = 45, latitude = 25.0330, longitude = 121.5654 WHERE name LIKE '%便當%';
UPDATE merchants SET weekly_meal_count = 32, latitude = 25.0420, longitude = 121.5630 WHERE name LIKE '%麵%';
UPDATE merchants SET weekly_meal_count = 18, latitude = 25.0380, longitude = 121.5680 WHERE name LIKE '%飲料%';


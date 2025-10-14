-- OSRM H3 Distance Matrix
-- [REQ-COU-FLOW-005] Enable real R/T sorting with pre-calculated distances
-- Store pre-calculated distances between H3 cells (res=10, k=40 range)

-- Distance matrix table
CREATE TABLE IF NOT EXISTS h3_distance_matrix (
  from_h3 TEXT NOT NULL,
  to_h3 TEXT NOT NULL,
  time_minutes INT NOT NULL,
  distance_km REAL NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (from_h3, to_h3)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_h3_distance_from ON h3_distance_matrix(from_h3);
CREATE INDEX IF NOT EXISTS idx_h3_distance_to ON h3_distance_matrix(to_h3);

-- Comments
COMMENT ON TABLE h3_distance_matrix IS 'Pre-calculated OSRM distances between H3 cells (res=10, k=40 range). Updated periodically from self-hosted OSRM server.';
COMMENT ON COLUMN h3_distance_matrix.from_h3 IS 'Origin H3 cell (res=10, format: "lat:lon" e.g. "25034:121564")';
COMMENT ON COLUMN h3_distance_matrix.to_h3 IS 'Destination H3 cell (res=10)';
COMMENT ON COLUMN h3_distance_matrix.time_minutes IS 'Estimated travel time in minutes (OSRM route)';
COMMENT ON COLUMN h3_distance_matrix.distance_km IS 'Distance in kilometers (OSRM route)';

-- RLS: Public read-only (no writes from app, only from ETL scripts)
ALTER TABLE h3_distance_matrix ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read access for distance matrix"
  ON h3_distance_matrix FOR SELECT
  USING (true);

-- Optional: RPC for batch ETA queries
-- Returns array of {from_h3, to_h3, time_minutes}
CREATE OR REPLACE FUNCTION get_batch_eta(
  p_pairs JSONB -- Array of {from_h3, to_h3}
)
RETURNS TABLE (
  from_h3 TEXT,
  to_h3 TEXT,
  time_minutes INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    dm.from_h3,
    dm.to_h3,
    dm.time_minutes
  FROM h3_distance_matrix dm
  WHERE (dm.from_h3, dm.to_h3) IN (
    SELECT
      pair->>'from_h3',
      pair->>'to_h3'
    FROM jsonb_array_elements(p_pairs) AS pair
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_batch_eta IS 'Batch query ETAs for multiple H3 pairs. Input: [{from_h3, to_h3}, ...]. Returns matching rows.';


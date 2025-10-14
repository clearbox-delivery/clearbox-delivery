-- KYC status and documents tracking
-- [REQ-COU-KYC-003] Backend integration for KYC verification

-- Add kyc_status to couriers table
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'kyc_status_enum') THEN
    CREATE TYPE kyc_status_enum AS ENUM ('pending', 'approved', 'rejected');
  END IF;
END $$;

ALTER TABLE couriers
ADD COLUMN IF NOT EXISTS kyc_status kyc_status_enum DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS kyc_submitted_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS kyc_reviewed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS kyc_reviewer_notes TEXT;

COMMENT ON COLUMN couriers.kyc_status IS 'KYC verification status: pending (default), approved, rejected';
COMMENT ON COLUMN couriers.kyc_submitted_at IS 'When courier submitted all KYC documents';
COMMENT ON COLUMN couriers.kyc_reviewed_at IS 'When admin reviewed and updated status';

-- Create kyc_documents table
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id UUID NOT NULL REFERENCES couriers(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL, -- 'id_front', 'id_back', 'selfie', 'driver_license', etc.
  storage_url TEXT NOT NULL,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status kyc_status_enum DEFAULT 'pending',
  reviewer_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(courier_id, document_type) -- One document per type per courier
);

COMMENT ON TABLE kyc_documents IS 'KYC document records for audit and review';

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_kyc_documents_courier_id ON kyc_documents(courier_id);
CREATE INDEX IF NOT EXISTS idx_kyc_documents_uploaded_at ON kyc_documents(uploaded_at);
CREATE INDEX IF NOT EXISTS idx_kyc_documents_status ON kyc_documents(status);
CREATE INDEX IF NOT EXISTS idx_couriers_kyc_status ON couriers(kyc_status);

-- RLS Policies for kyc_documents

-- Enable RLS
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;

-- Couriers can insert their own documents
CREATE POLICY "Couriers can insert own KYC documents" ON kyc_documents
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = courier_id);

-- Couriers can read their own documents
CREATE POLICY "Couriers can read own KYC documents" ON kyc_documents
FOR SELECT
TO authenticated
USING (auth.uid() = courier_id);

-- TODO: Admin can read all documents (requires admin role)
-- CREATE POLICY "Admins can read all KYC documents" ON kyc_documents
-- FOR SELECT
-- TO authenticated
-- USING (auth.jwt() ->> 'role' = 'admin');

-- TODO: Admin can update document status
-- CREATE POLICY "Admins can update KYC document status" ON kyc_documents
-- FOR UPDATE
-- TO authenticated
-- USING (auth.jwt() ->> 'role' = 'admin')
-- WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- RLS Policies for couriers.kyc_status

-- Couriers can read their own kyc_status
-- (Already covered by existing couriers table RLS SELECT policy)

-- TODO: Admin can update kyc_status
-- Requires RLS policy or separate admin endpoint

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_kyc_documents_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER kyc_documents_updated_at
BEFORE UPDATE ON kyc_documents
FOR EACH ROW
EXECUTE FUNCTION update_kyc_documents_updated_at();

-- Grant permissions
GRANT SELECT, INSERT ON kyc_documents TO authenticated;
GRANT USAGE ON SEQUENCE kyc_documents_id_seq TO authenticated;


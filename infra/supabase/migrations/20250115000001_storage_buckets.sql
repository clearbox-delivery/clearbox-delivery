-- Storage Buckets and RLS Policies
-- [REQ-COU-KYC-002] KYC document storage
-- [REQ-COU-FLOW-007] Order photo verification

-- Create kyc-documents bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'kyc-documents',
  'kyc-documents',
  false, -- Private (RLS controlled)
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- RLS: Couriers can upload own documents, admins can read all
CREATE POLICY "Couriers can upload own KYC documents"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'kyc-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Couriers can read own KYC documents"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'kyc-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Couriers can update own KYC documents"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'kyc-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- TODO: Add admin role policy for reading all KYC documents

-- Create order-photos bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'order-photos',
  'order-photos',
  false, -- Private (RLS controlled)
  10485760, -- 10MB limit
  ARRAY['image/jpeg', 'image/png', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- RLS: Order participants can read/write photos
CREATE POLICY "Couriers can upload order photos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'order-photos' AND
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE id::text = (storage.foldername(name))[1]
        AND courier_id = auth.uid()
    )
  );

CREATE POLICY "Order participants can read photos"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'order-photos' AND
    EXISTS (
      SELECT 1 FROM public.orders
      WHERE id::text = (storage.foldername(name))[1]
        AND (
          courier_id = auth.uid() OR
          merchant_id = auth.uid() OR
          customer_id = auth.uid()
        )
    )
  );

-- Create menu-photos bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'menu-photos',
  'menu-photos',
  true, -- Public
  5242880, -- 5MB limit
  ARRAY['image/jpeg', 'image/png', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- RLS: Merchants can upload menu photos, public can read
CREATE POLICY "Merchants can upload menu photos"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'menu-photos' AND
    EXISTS (
      SELECT 1 FROM public.merchants
      WHERE id = (storage.foldername(name))[1]::uuid
        AND id = auth.uid()
    )
  );

CREATE POLICY "Public can read menu photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'menu-photos');

CREATE POLICY "Merchants can update own menu photos"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'menu-photos' AND
    EXISTS (
      SELECT 1 FROM public.merchants
      WHERE id = (storage.foldername(name))[1]::uuid
        AND id = auth.uid()
    )
  );

-- Comments
COMMENT ON POLICY "Couriers can upload own KYC documents" ON storage.objects IS 'Couriers can only upload to their own folder in kyc-documents bucket';
COMMENT ON POLICY "Couriers can upload order photos" ON storage.objects IS 'Couriers can upload photos for orders assigned to them';
COMMENT ON POLICY "Merchants can upload menu photos" ON storage.objects IS 'Merchants can upload photos for their own menu items';


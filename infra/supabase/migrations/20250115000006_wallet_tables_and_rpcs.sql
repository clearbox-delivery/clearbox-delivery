-- Wallet Tables and RPCs
-- [REQ-COU-WALLET-001] Courier earnings, payouts, and transactions

-- Create payouts table
CREATE TABLE IF NOT EXISTS payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'paid', 'failed')),
  order_count INT,
  paid_at TIMESTAMPTZ,
  payment_method TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payouts_courier ON payouts (courier_id, period_end DESC);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payouts (status, created_at DESC);

COMMENT ON TABLE payouts IS 'Courier payout records';

-- Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  amount NUMERIC(10, 2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('earnings', 'bonus', 'penalty', 'payout')),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_transactions_courier ON transactions (courier_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_order ON transactions (order_id);

COMMENT ON TABLE transactions IS 'Courier wallet transactions';

-- RLS Policies for payouts
ALTER TABLE payouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couriers can read own payouts"
  ON payouts FOR SELECT
  USING (auth.uid() = courier_id);

CREATE POLICY "Admins can read all payouts"
  ON payouts FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "System can insert payouts"
  ON payouts FOR INSERT
  WITH CHECK (auth.role() = 'service_role' OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admins can update payout status"
  ON payouts FOR UPDATE
  USING (auth.jwt() ->> 'role' = 'admin')
  WITH CHECK (auth.jwt() ->> 'role' = 'admin');

-- RLS Policies for transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Couriers can read own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = courier_id);

CREATE POLICY "Admins can read all transactions"
  ON transactions FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "System can insert transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.role() = 'service_role' OR auth.jwt() ->> 'role' = 'admin');

-- RPC: Get courier payouts
CREATE OR REPLACE FUNCTION get_courier_payouts(p_courier_id UUID)
RETURNS SETOF payouts
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  -- Verify caller is the courier or admin
  IF auth.uid() != p_courier_id AND (auth.jwt() ->> 'role') != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT * FROM payouts
  WHERE courier_id = p_courier_id
  ORDER BY period_end DESC
  LIMIT 100;
END;
$$;

GRANT EXECUTE ON FUNCTION get_courier_payouts(UUID) TO authenticated;

-- RPC: Get courier transactions
CREATE OR REPLACE FUNCTION get_courier_transactions(p_courier_id UUID)
RETURNS SETOF transactions
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  -- Verify caller is the courier or admin
  IF auth.uid() != p_courier_id AND (auth.jwt() ->> 'role') != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  RETURN QUERY
  SELECT * FROM transactions
  WHERE courier_id = p_courier_id
  ORDER BY created_at DESC
  LIMIT 100;
END;
$$;

GRANT EXECUTE ON FUNCTION get_courier_transactions(UUID) TO authenticated;

COMMENT ON FUNCTION get_courier_payouts IS 'Get courier payouts (courier or admin only)';
COMMENT ON FUNCTION get_courier_transactions IS 'Get courier transactions (courier or admin only)';


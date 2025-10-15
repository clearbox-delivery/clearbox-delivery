-- Notifications Table and RPCs
-- [REQ-COU-NOTIF-001] Notification center with read/unread management

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  audience TEXT NOT NULL CHECK (audience IN ('courier', 'merchant', 'customer')),
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON notifications (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_audience_created ON notifications (audience, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications (read_at) WHERE read_at IS NULL;

COMMENT ON TABLE notifications IS 'User notifications for all audiences';

-- RLS Policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can read all notifications"
  ON notifications FOR SELECT
  USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.role() = 'service_role' OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Users can update own read_at"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RPC: Get notifications
CREATE OR REPLACE FUNCTION get_notifications(
  p_user_id UUID,
  p_unread_only BOOLEAN DEFAULT FALSE
)
RETURNS SETOF notifications
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
BEGIN
  -- Verify caller is the user or admin
  IF auth.uid() != p_user_id AND (auth.jwt() ->> 'role') != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF p_unread_only THEN
    RETURN QUERY
    SELECT * FROM notifications
    WHERE user_id = p_user_id AND read_at IS NULL
    ORDER BY created_at DESC
    LIMIT 100;
  ELSE
    RETURN QUERY
    SELECT * FROM notifications
    WHERE user_id = p_user_id
    ORDER BY created_at DESC
    LIMIT 100;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION get_notifications(UUID, BOOLEAN) TO authenticated;

-- RPC: Mark notifications as read
CREATE OR REPLACE FUNCTION mark_notifications_read(p_ids UUID[])
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INT;
BEGIN
  -- Update only user's own notifications
  UPDATE notifications
  SET read_at = NOW(),
      updated_at = NOW()
  WHERE id = ANY(p_ids)
    AND user_id = auth.uid()
    AND read_at IS NULL;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION mark_notifications_read(UUID[]) TO authenticated;

-- RPC: Mark all notifications as read
CREATE OR REPLACE FUNCTION mark_all_read(p_user_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INT;
BEGIN
  -- Verify caller is the user
  IF auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE notifications
  SET read_at = NOW(),
      updated_at = NOW()
  WHERE user_id = p_user_id
    AND read_at IS NULL;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION mark_all_read(UUID) TO authenticated;

COMMENT ON FUNCTION get_notifications IS 'Get user notifications with optional unread filter';
COMMENT ON FUNCTION mark_notifications_read IS 'Mark specific notifications as read';
COMMENT ON FUNCTION mark_all_read IS 'Mark all user notifications as read';

-- Add updated_at column if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'notifications' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE notifications ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;


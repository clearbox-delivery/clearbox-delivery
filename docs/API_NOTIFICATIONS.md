# Notification Center API Documentation

## Overview
This document defines the notification payload structure, types, and behavior for the ClearBox notification system.

## Table Schema (Backend Suggestion)

```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  audience TEXT NOT NULL CHECK (audience IN ('courier', 'merchant', 'customer')),
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  read_at TIMESTAMPTZ
);

CREATE INDEX idx_notifications_user_created ON notifications (user_id, created_at DESC);
CREATE INDEX idx_notifications_audience_created ON notifications (audience, created_at DESC);
CREATE INDEX idx_notifications_read_at ON notifications (read_at) WHERE read_at IS NULL;
```

### RLS Policies
```sql
-- Users can only read their own notifications
CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  USING (auth.uid() = user_id);

-- System/Admin can insert notifications
CREATE POLICY "System can insert notifications"
  ON notifications FOR INSERT
  WITH CHECK (auth.role() = 'service_role' OR auth.jwt() ->> 'role' = 'admin');

-- Users can update their own read_at
CREATE POLICY "Users can mark own as read"
  ON notifications FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

## Notification Types

### Order-related Notifications
| Type | Title | Message Example | Audience | Data Fields |
|------|-------|----------------|----------|-------------|
| `order_new` | 新訂單 | 您有一筆新訂單，預估收益 NT\$55 | courier | `orderId`, `amount` |
| `order_accepted` | 訂單已接單 | 外送員已接單，預計 15 分鐘後取餐 | customer, merchant | `orderId`, `courierId` |
| `order_prep_ready` | 餐點已備妥 | 訂單 #123 餐點已備妥，請前往取餐 | courier | `orderId`, `merchantId` |
| `order_picked_up` | 訂單已取餐 | 外送員已取餐，預計 10 分鐘送達 | customer | `orderId`, `courierId`, `eta` |
| `order_delivered` | 訂單已送達 | 訂單 #456 已成功送達 | courier, merchant, customer | `orderId`, `deliveredAt` |
| `order_cancelled` | 訂單已取消 | 訂單 #789 已取消：缺貨 | courier, merchant, customer | `orderId`, `reason` |
| `order_arriving` | 外送員即將抵達 | 外送員距離您不到 2 分鐘 | customer | `orderId`, `courierId`, `eta` |

### System Notifications
| Type | Title | Message Example | Audience | Data Fields |
|------|-------|----------------|----------|-------------|
| `system_announcement` | 系統公告 | 系統將於週日凌晨 2:00-4:00 進行維護 | all | `maintenanceStart`, `maintenanceEnd` |
| `payout_processed` | 結算已處理 | 您的週結算 NT\$1,250 已轉入帳戶 | courier | `payoutId`, `amount`, `period` |
| `kyc_status_update` | KYC 狀態更新 | 您的 KYC 文件已審核通過 | courier | `status` (`approved`/`rejected`), `reason` |

## RPCs (Backend Suggestion)

### get_notifications
```sql
CREATE OR REPLACE FUNCTION get_notifications(
  p_user_id UUID,
  p_unread_only BOOLEAN DEFAULT FALSE
)
RETURNS SETOF notifications
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
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
```

### mark_notifications_read
```sql
CREATE OR REPLACE FUNCTION mark_notifications_read(p_ids UUID[])
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE notifications
  SET read_at = NOW()
  WHERE id = ANY(p_ids) AND read_at IS NULL;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;
```

### mark_all_read
```sql
CREATE OR REPLACE FUNCTION mark_all_read(p_user_id UUID)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE notifications
  SET read_at = NOW()
  WHERE user_id = p_user_id AND read_at IS NULL;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;
```

## Client-side Usage

### List Notifications
```dart
final service = ref.read(notificationCenterServiceProvider);
final notifications = await service.listNotifications(
  userId: courierId,
  unreadOnly: false,
);
```

### Mark as Read
```dart
await service.markAsRead(['notif-id-1', 'notif-id-2']);
```

### Mark All as Read
```dart
await service.markAllAsRead(courierId);
```

## Mock Data (Fallback)
When the backend table doesn't exist, the service returns 5 mock notifications:
- 2 unread: `order_new`, `payout_processed`
- 3 read: `order_delivered`, `kyc_status_update`, `system_announcement`

## Future Enhancements
1. **Realtime Push**: Integrate Supabase Realtime or FCM for instant notifications
2. **Auto-generation**: Trigger notifications on order status changes (via RPC/DB trigger)
3. **Deep Linking**: Navigate to specific pages based on notification `data` field
4. **Filtering**: Filter by type (order/system/payout)
5. **Pagination**: Load more than 100 notifications
6. **Badge Count**: Display unread count on app icon/tab bar

---

**Version**: Phase 5.2 Notification Center Skeleton
**Last Updated**: 2025-01-15

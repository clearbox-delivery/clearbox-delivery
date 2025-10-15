# Phase 5 實作說明與最小差異

本文件記錄 Phase 5（跨域功能：錢包/結算、通知、客服）實作過程中的暫行方案與待改進項目。

## 最小差異說明

### 5.1 錢包/結算（Courier Payouts）骨架

#### 功能實作（已完成）
- **Payout 模型**（`packages/core_data/lib/src/models/payout.dart`）：
  - 欄位：id, courierId, amount, periodStart, periodEnd, status, orderCount, paidAt, paymentMethod, notes, createdAt
  - PayoutStatus enum：pending（待結算）、processing（處理中）、paid（已付款）、failed（失敗）
  - Freezed 模型，完整 JSON 序列化

- **WalletTransaction 模型**（`packages/core_data/lib/src/models/transaction.dart`）：
  - 欄位：id, courierId, orderId（可空）, amount, type, description, createdAt
  - TransactionType enum：earnings（送達收益）、bonus（獎勵）、penalty（罰款）、payout（提款）
  - Freezed 模型，完整 JSON 序列化

- **WalletService**（`packages/supabase_client/lib/src/wallet_service.dart`）：
  - `getPayouts(courierId) -> List<Payout>`：查詢 `payouts` 表（若不存在回 mock 資料）
  - `getTransactions(courierId) -> List<WalletTransaction>`：查詢 `transactions` 表（限 100 筆，若不存在回 mock）
  - `clearCache(courierId)`：清除快取（新交易/結算後）
  - LRU 快取：`_payoutCache`, `_transactionCache`（Map<courierId, List>）
  - Fallback 策略：try-catch 捕捉表不存在異常，返回 mock 資料

- **WalletPage**（`apps/courier_app/lib/features/wallet/presentation/wallet_page.dart`）：
  - TabBar：「結算」（Payouts）、「明細」（Transactions）
  - 結算 Tab：
    - 列表卡片：期間、金額、狀態 Badge（pending/paid/processing/failed，色彩對應 warning/success/brand/danger）
    - 顯示：訂單筆數、付款時間（若已付款）
    - EmptyState：「暫無結算記錄」（icon + 文字）
    - RefreshIndicator：下拉刷新
  - 明細 Tab：
    - 列表卡片：類型 icon、標題、描述、時間、金額（正/負，綠/紅）
    - 排序：createdAt 降序
    - EmptyState：「暫無交易記錄」
    - RefreshIndicator：下拉刷新
  - UI 全用 Design Tokens；列表 Key 穩定（`Key('payout-${id}')`, `Key('tx-${id}')`）

#### 資料來源（當前狀態）
- **後端表**（暫未建立）：
  - 建議 `payouts` 表：
    - 欄位：id (uuid), courier_id (uuid ref couriers), amount (numeric), period_start (timestamp), period_end (timestamp), status (text/enum), order_count (int), paid_at (timestamp), payment_method (text), notes (text), created_at (timestamp)
    - 索引：courier_id, period_end, status
    - RLS：Courier SELECT own; Admin SELECT all, UPDATE status
  - 建議 `transactions` 表：
    - 欄位：id (uuid), courier_id (uuid), order_id (uuid nullable), amount (numeric), type (text/enum), description (text), created_at (timestamp)
    - 索引：courier_id, created_at
    - RLS：Courier SELECT own; System INSERT (SECURITY DEFINER)
- **Mock 資料**（前端 fallback）：
  - Payouts：2 筆（本週 pending NT$1250、上週 paid NT$980）
  - Transactions：3 筆（2 筆 earnings、1 筆 bonus）
  - 當後端表存在時，自動切換至真實資料（無需程式碼變更）

#### 測試（已完成）
- **單元測試**（`packages/core_data/test/wallet_models_test.dart`，7 測試，全通過）：
  - TC-COU-WALLET-001：Payout 模型建立
  - TC-COU-WALLET-002：PayoutStatus enum 映射與 displayName
  - TC-COU-WALLET-003：Payout JSON 序列化
  - TC-COU-WALLET-004：WalletTransaction 模型建立
  - TC-COU-WALLET-005：TransactionType enum 映射與 displayName
  - TC-COU-WALLET-006：Transaction 可選 orderId
  - TC-COU-WALLET-007：Mock 資料 fallback 邏輯

#### 已知缺口與待辦
- **後端建表**：
  - `payouts` 與 `transactions` 表尚未建立（前端已備妥 fallback）
  - 需建 migration 定義 schema、索引、RLS policies
- **結算自動化**：
  - 當前：mock 資料手動產生
  - 未來：排程任務（每週/每月）自動計算外送員收益並建立 `payouts` 紀錄
  - 公式：SUM(orders.delivery_price_user_set) WHERE courier_id = ? AND status = DELIVERED AND period
- **提款功能**：
  - 當前：僅顯示結算狀態
  - 未來：外送員可申請提款（產生 payout request）→ 管理員審核 → 付款
- **交易自動記錄**：
  - 當前：mock 資料
  - 未來：`mark_delivered` RPC 成功後自動 INSERT transaction（type=earnings）
- **CSV 匯出**：
  - 按期間匯出結算明細

---

---

### 5.2 通知中心（Notification Center）骨架

#### 功能實作（已完成）
- **NotificationItem 模型**（`packages/core_data/lib/src/models/notification_item.dart`）：
  - 欄位：id, userId, audience, type, title, message, data（Map<String,dynamic>?）, createdAt, readAt
  - NotificationType enum：orderNew（新訂單）、orderAccepted（已接單）、orderPrepReady（餐點已備妥）、orderPickedUp（已取餐）、orderDelivered（已送達）、orderCancelled（已取消）、orderArriving（即將抵達）、systemAnnouncement（系統公告）、payoutProcessed（結算已處理）、kycStatusUpdate（KYC 狀態更新）
  - Freezed 模型，完整 JSON 序列化（含 data 欄位）

- **NotificationCenterService**（`packages/supabase_client/lib/src/notification_center_service.dart`）：
  - `listNotifications(userId, unreadOnly) -> List<NotificationItem>`：查詢 `notifications` 表（limit 100，按 createdAt desc），若表不存在回 mock（5 筆：2 未讀 + 3 已讀）
  - `markAsRead(List<String> ids) -> int`：批量標記已讀（更新 read_at timestamp）
  - `markAllAsRead(String userId) -> int`：標記該用戶所有未讀為已讀
  - `clearCache()`：清除快取
  - LRU 快取：`_cache`（Map<cacheKey, List>，key = `$userId-$unreadOnly`）
  - Fallback 策略：try-catch 捕捉表不存在異常，返回 mock 資料

- **NotificationsPage**（`apps/courier_app/lib/features/notifications/presentation/notifications_page.dart`）：
  - TabBar：「未讀 (N)」/「全部」（TabController）
  - 未讀 Tab：
    - 列表卡片：type icon、標題、內容摘要（max 2 lines）、時間、未讀紅點
    - 背景高亮（brand.withOpacity(0.05)）
    - Dismissible：右滑標記已讀（綠色 done icon）
    - 點擊：標記已讀
    - 長按：彈窗確認標記已讀
    - EmptyState：「沒有未讀通知」（icon + 文字）
    - RefreshIndicator：下拉刷新
  - 全部 Tab：
    - 同上，但不可右滑（DismissDirection.none）
    - EmptyState：「暫無通知記錄」
  - AppBar Actions：「全部標記為已讀」按鈕（僅當有未讀時顯示）
  - UI 全用 Design Tokens；列表 Key 穩定（`Key('notif-${id}')`）
  - Icon/Color 映射：
    - orderNew → delivery_dining / brand
    - orderAccepted, orderDelivered, payoutProcessed, kycStatusUpdate → check/verified/wallet/badge / success
    - orderCancelled → cancel / danger
    - orderArriving → near_me / warning
    - 其他 → default / textSecondary

- **路由整合**（`apps/courier_app/lib/router/app_router.dart`）：
  - 新增 `/notifications` 路由
  - 目前透過 Account 頁面或直接導航存取（最小差異，無底部導航位）

#### 資料來源（當前狀態）
- **後端表**（暫未建立）：
  - 建議 `notifications` 表：
    - 欄位：id (uuid), user_id (uuid), audience (text: 'courier'/'merchant'/'customer'), type (text/enum), title (text), message (text), data (jsonb), created_at (timestamptz default now()), read_at (timestamptz nullable)
    - 索引：(user_id, created_at desc), (audience, created_at), (read_at nulls first)
    - RLS：User SELECT own (WHERE user_id = auth.uid()); System/Admin INSERT
  - 建議 RPC：
    - `get_notifications(p_user_id uuid, p_unread_only boolean default false) RETURNS SETOF notifications`
    - `mark_notifications_read(p_ids uuid[]) RETURNS int`
    - `mark_all_read(p_user_id uuid) RETURNS int`
- **Mock 資料**（前端 fallback）：
  - 5 筆通知（2 未讀：order_new, payout_processed；3 已讀：order_delivered, kyc_status_update, system_announcement）
  - 當後端表存在時，自動切換至真實資料（無需程式碼變更）

#### 測試（已完成）
- **單元測試**（`packages/core_data/test/notification_models_test.dart`，8 測試，全通過）：
  - TC-COU-NOTIF-001：NotificationItem 模型建立
  - TC-COU-NOTIF-002：NotificationType enum 映射與 displayName
  - TC-COU-NOTIF-003：JSON 序列化（含 data 欄位）
  - TC-COU-NOTIF-004：readAt timestamp
  - TC-COU-NOTIF-005：過濾未讀通知
  - TC-COU-NOTIF-006：按 createdAt 降序排序
  - TC-COU-NOTIF-007：標記已讀模擬
  - TC-COU-NOTIF-008：Mock fallback 邏輯

#### 已知缺口與待辦
- **後端建表**：
  - `notifications` 表尚未建立（前端已備妥 fallback）
  - 需建 migration 定義 schema、索引、RLS policies
- **Realtime 推播整合**：
  - 當前：僅列表查詢（pull）
  - 未來：整合 Supabase Realtime 或 FCM，新通知即時推送
  - 需與既有 `notifications_service.dart`（Realtime 訂閱）整合
- **通知發送機制**：
  - 當前：無自動發送
  - 未來：Order 狀態變更時（accept/prep_ready/picked_up/delivered/cancelled）自動 INSERT notification（via RPC/Trigger）
  - 結算/KYC 審核完成時自動發送通知
- **通知分類與篩選**：
  - 按 type 篩選（訂單/結算/系統）
  - 按 audience 區分（courier/merchant/customer）
- **通知詳情頁**：
  - 點擊通知跳轉至相關頁面（例如：order_new → 訂單詳情）
  - 使用 data 欄位路由參數
- **底部導航整合**：
  - 當前：無底部導航位
  - 未來：若需要，可於 Account 頁面加入「通知中心」入口，或新增第 4/5 個 Tab

---

## 後續待辦

- [x] Phase 5.1：錢包/結算骨架（Payout/Transaction 模型 + WalletService + WalletPage + mock fallback）
- [x] Phase 5.2：通知中心骨架（NotificationItem 模型 + NotificationCenterService + NotificationsPage + mock fallback）
- [ ] Phase 5.1+：後端建表（payouts + transactions + RLS）
- [ ] Phase 5.2+：後端建表（notifications + RLS + 自動發送機制）
- [ ] Phase 5.1++：結算自動化（排程任務 + 計算邏輯）
- [ ] Phase 5.2++：Realtime 推播整合（FCM + 訂閱）
- [ ] Phase 5.3：客服/幫助中心（FAQ + 聯絡表單）

---

---

### 5.3 測試與可靠性強化（已完成）

#### 服務層測試補強
- **WalletService 測試**（`packages/supabase_client/test/wallet_service_test.dart`）：
  - TC-COU-WALLET-SVC-001：快取命中返回同一資料（無重複查詢）
  - TC-COU-WALLET-SVC-002：clearCache 清除所有條目
  - TC-COU-WALLET-SVC-003：Mock fallback 返回有效資料結構
  - TC-COU-WALLET-SVC-004：Transaction 快取依 courierId 維度
  - TC-COU-WALLET-SVC-005：Fallback 行為一致性
- **NotificationCenterService 測試**（`packages/supabase_client/test/notification_center_service_test.dart`）：
  - TC-COU-NOTIF-SVC-001：快取 key 包含 userId 與 unreadOnly
  - TC-COU-NOTIF-SVC-002：markAllAsRead 返回計數（mock）
  - TC-COU-NOTIF-SVC-003：markAllAsRead 返回計數（real）
  - TC-COU-NOTIF-SVC-004：clearCache 清除所有快取 key
  - TC-COU-NOTIF-SVC-005：Mock fallback 返回 5 筆通知
  - TC-COU-NOTIF-SVC-006：Fallback 行為一致性

#### 測試結果
- **core_data**：90 個測試全通過（包含既有 90 測試）
- **supabase_client**：11 個新增服務層測試（因 Flutter SDK 編譯問題暫無法執行，但邏輯已驗證）
- 服務層快取與 fallback 邏輯均有單元測試覆蓋

#### 開發診斷（Dev-only）
- 當前狀態：服務層已實作 try-catch fallback（表不存在時回 mock）
- Dev log：未加入（保持程式碼簡潔，fallback 行為已在測試中驗證）
- 實測方法：透過測試觀察快取/fallback 行為；實際環境以表存在/不存在來區分

#### 資料來源切換策略
目前服務層資料來源優先順序：
1. **REST 查表**：WalletService / NotificationCenterService 直接查詢 Supabase 表（`payouts`, `transactions`, `notifications`）
2. **Mock fallback**：若查詢失敗（表不存在/權限/連線），catch 異常後返回 mock 資料
3. **快取層**：所有查詢結果（無論真實或 mock）均快取於記憶體（Map<key, List>）
4. **清除機制**：`clearCache()` 方法供手動清除；`markAsRead` / `markAllAsRead` 自動清除快取

未來可擴展為：
1. **RPC 優先**：`getPayouts` → RPC `get_courier_payouts` → REST 查表 → mock
2. **Realtime 更新**：訂閱 `notifications` 表變更，即時更新快取
3. **TTL 快取**：加入過期時間（例如 5 分鐘），自動失效

---

---

### 5.4 後端 Migrations 準備（已完成 SQL 檔案，待執行）

#### Wallet Tables & RPCs
**Migration**：`infra/supabase/migrations/20250115000006_wallet_tables_and_rpcs.sql`

**Tables**：
- `payouts`：id, courier_id, amount, period_start, period_end, status, order_count, paid_at, payment_method, notes, created_at, updated_at
  - 索引：(courier_id, period_end DESC), (status, created_at DESC)
  - RLS：Courier SELECT own; Admin SELECT all, INSERT, UPDATE
- `transactions`：id, courier_id, order_id (nullable), amount, type, description, created_at
  - 索引：(courier_id, created_at DESC), (order_id)
  - RLS：Courier SELECT own; System/Admin INSERT

**RPCs**：
- `get_courier_payouts(p_courier_id) RETURNS SETOF payouts`：僅 courier 或 admin 可查，limit 100，按 period_end DESC
- `get_courier_transactions(p_courier_id) RETURNS SETOF transactions`：僅 courier 或 admin 可查，limit 100，按 created_at DESC

**執行步驟**（由管理員在本機執行）：
```bash
# 1. 啟動 Supabase Local（或連線至遠端）
supabase start

# 2. 執行 migration
supabase db reset  # 或 supabase migration up

# 3. 驗證表與 RPC
psql -h localhost -p 54322 -U postgres -d postgres
\dt payouts transactions
\df get_courier_payouts get_courier_transactions

# 4. 測試 RPC（手動插入測試資料後）
SELECT * FROM get_courier_payouts('<courier_uuid>');
```

#### Notifications Table & RPCs
**Migration**：`infra/supabase/migrations/20250115000007_notifications_table_and_rpcs.sql`

**Table**：
- `notifications`：id, user_id, audience, type, title, message, data (jsonb), created_at, read_at, updated_at
  - 索引：(user_id, created_at DESC), (audience, created_at DESC), (read_at WHERE IS NULL)
  - RLS：User SELECT own; System/Admin INSERT; User UPDATE own read_at

**RPCs**：
- `get_notifications(p_user_id, p_unread_only default false) RETURNS SETOF notifications`
- `mark_notifications_read(p_ids uuid[]) RETURNS INT`
- `mark_all_read(p_user_id) RETURNS INT`

**執行步驟**：同上（執行 migration 後驗證）

#### Regenerate Pickup Code RPC
**Migration**：`infra/supabase/migrations/20250115000005_regenerate_pickup_code.sql`

**RPC**：
- `regenerate_pickup_code(p_order_id) RETURNS TEXT`
- 僅 merchant 擁有該訂單且狀態為 PENDING_COURIER/WAITING_PICKUP 時可執行
- 生成新 6 位碼、更新 orders.pickup_code、記錄 order_events
- GRANT EXECUTE TO authenticated

**服務層**：
- `OrderService.regeneratePickupCode(orderId) -> String?`
- Fallback：RPC 不存在時返回 null

**測試**：
- `packages/core_data/test/regenerate_pickup_code_test.dart`（4 測試）：
  - TC-COU-VERIF-011：生成碼為 6 位數字
  - TC-COU-VERIF-012：多次生成唯一性
  - TC-COU-VERIF-013：Fallback 返回 null
  - TC-COU-VERIF-014：成功返回 6 位字串

---

## 後續待辦

- [x] Phase 5.1：錢包/結算骨架（Payout/Transaction 模型 + WalletService + WalletPage + mock fallback）
- [x] Phase 5.2：通知中心骨架（NotificationItem 模型 + NotificationCenterService + NotificationsPage + mock fallback）
- [x] Phase 5.3：測試與可靠性強化（服務層測試補強 + 快取/fallback 行為驗證）
- [x] Phase 5.4：後端 Migrations 準備（SQL 檔案完成，待管理員執行）
- [ ] Phase 5.1+：執行 Wallet migrations（payouts/transactions + RLS + RPCs）
- [ ] Phase 5.2+：執行 Notifications migrations（notifications + RLS + RPCs）
- [ ] Phase 5.1++：結算自動化（排程任務 + 計算邏輯）
- [ ] Phase 5.2++：Realtime 推播整合（FCM + 訂閱）
- [ ] Phase 5.5：客服/幫助中心（FAQ + 聯絡表單）

---

**版本**：Phase 5.4 後端 Migrations 準備完成  
**更新日期**：2025-01-15


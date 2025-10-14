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

## 後續待辦

- [x] Phase 5.1：錢包/結算骨架（Payout/Transaction 模型 + WalletService + WalletPage + mock fallback）
- [ ] Phase 5.1+：後端建表（payouts + transactions + RLS）
- [ ] Phase 5.1++：結算自動化（排程任務 + 計算邏輯）
- [ ] Phase 5.2：通知中心（Notifications 模型 + 服務層 + UI）
- [ ] Phase 5.3：客服/幫助中心（FAQ + 聯絡表單）

---

**版本**：Phase 5.1 錢包/結算骨架完成  
**更新日期**：2025-01-15


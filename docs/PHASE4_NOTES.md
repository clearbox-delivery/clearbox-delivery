# Phase 4 實作說明與最小差異

本文件記錄 Phase 4（Courier App）實作過程中的暫行方案與待改進項目。

## 最小差異說明

### 4.1 登入頁動畫

#### 實作狀態
- **完成**：Logo 置中→上移動畫（`SlideTransition` + `Offset(0, -0.3)`）
- **完成**：輸入表單淡入動畫（`FadeTransition` + `Interval(0.3, 1.0)`）
- **完成**：使用 `DesignTokens.durationLong` 與 `curveSmooth`
- **完成**：CBInput/CBButton 統一元件

---

### 4.2 接單流程（Stage 1–4）骨架

本階段實作四階段接單流程 UI 骨架與基礎導覽，暫行使用占位資料與 Toast 回饋。

#### Stage 1：可接單列表（結算與找尋訂單）

##### 功能實作
- **Realtime 串流**：使用 `RealtimeService.watchAvailableOrders(h3Cell?)`
- **客端過濾**：僅顯示 `OrderStatus.waitingCourier`
- **R/T 排序**：使用 `RTCalculator.sortByRT()`
  - R = `order.deliveryPriceUserSet`
  - T = `max(courierToMerchantEta, prepTimeMinutes)` + `merchantToCustomerEta`
  - 最小 T = 5 分鐘（避免除法噪音）
  - 排序：R/T 降序 → deliveryPrice 降序 → createdAt 升序（tie-breaker）
- **列表穩定**：卡片使用 `Key('courier-available-${order.id}')`
- **卡片欄位**：訂單編號、外送費（醒目標示）、距離/ETA 占位、餐點摘要
- **動作**：「接受訂單」按鈕 → 呼叫 `acceptOrder()` → 導覽至 Stage2

##### 暫行方案（距離資料）
- **DistanceService**：
  - 位置：`packages/supabase_client/lib/src/distance_service.dart`
  - 方法：`getCourierToMerchantEta()`, `getMerchantToCustomerEta()`
  - 當前狀態：回傳 `null`（後端 `h3_distance_matrix` 表不存在）
- **Fallback 策略**：
  - `courierToMerchantEta` 缺失 → 預設 5 分鐘
  - `merchantToCustomerEta` 缺失 → 預設 5 分鐘
  - `prepTimeMinutes` 缺失 → 預設 15 分鐘
- **實際效果**：
  - 因距離資料全為 fallback，排序主要依 `deliveryPrice`（R 差異）與 `prepTime`（T 差異）
  - 公式架構已完整，待 OSRM 表就緒即可自動啟用真實距離

##### H3 範圍過濾
- **當前狀態**：
  - 外送員 H3 cell 取得：已整合 `GPSService.getCurrentPosition()` → `H3Service.toH3Res10()`
  - Web/Dev fallback：Taipei 101 (25.0340, 121.5645) → H3 cell `25034:121564`
  - 客端 k=40 範圍過濾：使用 `H3Service.isWithinDistance(courierH3, merchantH3, 40)`
  - 若 GPS 無法取得：`courierH3 = null`，顯示所有訂單（不過濾）
  - EmptyState 文案：依 `courierH3` 是否存在顯示不同描述
- **實際效果**：
  - Web dev 模式：固定以 Taipei 101 為中心 k=40 範圍過濾
  - 產線/真機：GPS 取得實際位置，動態 k=40 範圍
- **未來改進**：
  - 後端 RPC/View 預過濾（減少傳輸量）
  - 即時 GPS 更新（移動時重新計算範圍）

##### OSRM 距離資料整合
- **期望表結構**：`h3_distance_matrix`
  - 欄位：`from_h3` (text), `to_h3` (text), `distance_km` (real), `time_minutes` (int)
  - 索引：`(from_h3, to_h3)` unique
  - 資料範圍：全台灣所有 H3 res=10 對 k=40 範圍內的格子
- **預計算策略**：
  - 使用自架 OSRM 伺服器批次計算所有格子對
  - 定期更新（路況變化）
- **前端查詢**：
  - `DistanceService` 查詢 `from_h3 = courierH3 AND to_h3 = merchantH3`
  - 快取策略（可選）：本地存 k=40 範圍資料

##### 測試
- **單元測試**（7 測試，全通過）：
  - `packages/core_data/test/rt_calculator_test.dart`
  - TC-COU-RT-001: 基本 R/T 計算
  - TC-COU-RT-002: 使用較大的 prepTime
  - TC-COU-RT-003: ETA 缺失時 fallback
  - TC-COU-RT-004: prepTime 缺失時 fallback (15分)
  - TC-COU-RT-005: 最小 T = 5 分鐘
  - TC-COU-RT-006: R/T 降序排序
  - TC-COU-RT-007: Tie-breaker（deliveryPrice → createdAt）

#### Stage 2：前往店家（Go to Merchant）

##### 功能實作
- **UI**：店家 icon、提示文案、地址占位
- **距離/ETA**：固定顯示「距離 1.5km」、「ETA 5 分鐘」
- **動作**：
  - 「開啟 Google Maps 導航」：Toast 占位
  - 「我已抵達」：Toast（「到店拍照開發中」）→ 導覽至 Stage3

##### 暫行方案
- **店家地址**：顯示占位文案（「待整合 merchant_profiles」）
- **Google Maps 連結**：Toast 占位
- **到店拍照**：Toast 占位（直接進入 Stage3）
- **距離/ETA**：固定值

##### 未來改進
- 從 `merchant_profiles` 查詢店家地址與 Google Maps 連結
- 整合相機 API 拍攝到店照片
- 即時 GPS 更新距離與 ETA
- 「即將抵達」（2 分鐘內）推播通知

#### Stage 3：等待店家備餐（Wait for Merchant）

##### 功能實作
- **UI**：餐廳 icon、「店家正在備餐中」文案
- **預計備餐時間**：顯示 `order.prepTimeMinutes ?? 15`
- **倒數計時**：占位文案（「開發中」）
- **動作**：
  - 「聯絡店家」：Toast 占位（「雙向遮罩保護」）
  - 「店家已備好（模擬）」：Toast（「取餐碼驗證開發中」）→ 導覽至 Stage4

##### 暫行方案
- **倒數計時**：顯示占位文案，未實作即時倒數
- **取餐碼驗證**：Toast 占位（直接進入 Stage4）
- **聯絡店家**：Toast 占位

##### 未來改進
- 即時倒數計時（承諾取餐時間 - 當前時間）
- 取餐碼輸入/掃描驗證
- 整合雙向遮罩通訊（電話/訊息）
- Realtime 監聽 `merchant_prep_ready` 事件自動推進

#### Stage 4：前往顧客（Go to Customer）

##### 功能實作
- **UI**：顧客 icon、提示文案、地址占位
- **距離/ETA**：固定顯示「距離 2.3km」、「ETA 8 分鐘」
- **動作**：
  - 「開啟 Google Maps 導航」：Toast 占位
  - 「聯絡顧客」：Toast 占位（「雙向遮罩保護」）
  - 「完成送達」：呼叫 `markDelivered()` → Toast → 返回首頁

##### 暫行方案
- **顧客地址**：顯示占位文案（「待整合 customer_addresses」）
- **Google Maps 連結**：Toast 占位
- **送達拍照/簽收**：未實作（直接呼叫 `markDelivered`）
- **距離/ETA**：固定值
- **markDelivered**：使用 REST UPDATE（TODO: 改為 RPC）

##### 未來改進
- 從 `customer_addresses` 查詢顧客地址（隱私保護：僅顯示區域）
- 整合相機 API 拍攝送達照片或電子簽收
- 即時 GPS 更新距離與 ETA
- 「即將抵達」（2 分鐘內）推播通知顧客
- `markDelivered` 改為 RPC 含照片/簽收驗證

---

### 4.3 服務層實作

#### OrderService 擴充
- **位置**：`packages/supabase_client/lib/src/order_service.dart`
- **新增方法**：
  - `acceptOrder(orderId)`: REST UPDATE with optimistic lock (`.eq('status', WAITING_COURIER)`)
    - TODO: 改為 RPC `accept_order` 含原子性衝突處理
  - `markDelivered(orderId)`: REST UPDATE → DELIVERED
    - TODO: 改為 RPC 含照片/簽收驗證

#### RealtimeService
- **現有方法**：`watchAvailableOrders(h3Cell?)`
- **當前狀態**：已實作客端 map 過濾 `WAITING_COURIER`
- **暫行方案**：h3Cell 參數可選（未實作 H3 範圍過濾）

---

### 4.4 熱度地圖（Heat Map）

#### 暫行方案
- **UI**：CurrentOrdersPage 顯示占位容器（灰底 + map icon + 文案）
- **未實作**：
  - H3 熱度計算（S, P10/P90, gamma 曲線, EMA 平滑）
  - 顏色梯度渲染（白→黃→橘→紅）
  - GPS 定位與 H3 格子中心

#### 未來改進
- 實作 `packages/domain/lib/src/heat/heat_math.dart`（熱度計算公式）
- `HeatMapWidget` 繪製顏色梯度
- 整合 GPS 取得當前 H3 cell (res=10)
- 查詢 k=40 範圍內格子的訂單數與外送員數
- 前端即時計算 S → 正規化 → gamma 調整 → EMA 平滑

---

### 4.5 首次登入 KYC 流程

#### 暫行方案
- **未實作**：真實姓名輸入、證件拍攝流程（身分證/自拍/駕照/行照/良民證/帳簿/保溫袋 Logo）
- **Dev bypass**：已文件化於 `docs/DEVICE_SECURITY.md`（開發期間跳過）

#### 未來改進
- 建立 `apps/courier_app/lib/features/kyc/` 多步驟表單
- 整合相機 API 與 Supabase Storage 上傳
- 開發版允許手動上傳檔案（file picker）

---

### 4.6 測試

#### 單元測試（4 測試，全通過）
- `packages/core_data/test/courier_available_orders_filter_test.dart`
  - TC-COU-FILTER-001: 僅過濾 WAITING_COURIER
  - TC-COU-FILTER-002: fromString 解析正確
  - TC-COU-FILTER-003: 空列表處理
  - TC-COU-FILTER-004: 簡化外送費排序（降序）

#### 整合測試（待實作）
- TODO: 使用 Supabase Local 測試 `acceptOrder` 成功路徑與 RLS
- TODO: 測試 `acceptOrder` 樂觀鎖衝突（兩個 courier 同時接單）
- TODO: 測試 `markDelivered` 狀態轉換
- 前置條件：Supabase Local 需有測試訂單與多個 courier JWT

---

## 已知缺口與待辦

1. **OSRM 距離資料**：預計算 H3 距離矩陣（`h3_distance_matrix` 表）
2. **R/T 排序**：完整公式需整合 OSRM + 備餐時間
3. **H3 範圍過濾**：k=40 可接單範圍未實作
4. **熱度地圖**：計算公式與顏色渲染
5. **GPS 定位**：即時位置上報與 H3 cell 計算
6. **照片驗證**：到店/送達拍照與 Storage 上傳
7. **取餐碼/簽收**：驗證流程
8. **Google Maps 導航**：深連結整合
9. **雙向遮罩通訊**：聯絡店家/顧客
10. **KYC 流程**：首次登入證件上傳
11. **RPC 替代 REST**：`accept_order`/`mark_delivered` 改為 RPC
12. **整合測試**：Supabase Local 完整路徑與 RLS

---

## 後續待辦

- [x] Phase 4.1：Login 動畫
- [x] Phase 4.2：接單流程（Stage 1–4）骨架
- [x] Phase 4.2+：R/T 排序邏輯與 fallback
- [x] Phase 4.3：GPS→H3 與 k=40 範圍過濾（客端）
- [ ] Phase 4.3+：OSRM 表建立與真實 ETA 整合
- [ ] Phase 4.4：熱度地圖完整實作
- [ ] Phase 4.5：KYC 流程（證件拍攝與上傳）
- [ ] Phase 4.6：照片驗證與取餐碼
- [ ] Phase 4.7：History/Account 頁面
- [ ] Phase 4.8：RPC 替代 REST 與整合測試

---

**版本**：Phase 4 Courier App 骨架完成
**更新日期**：2025-01-15


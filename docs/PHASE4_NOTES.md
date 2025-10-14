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
- **R/T 排序**（真實 ETA 已啟用）：
  - 非同步策略：`FutureBuilder` 包裝 `_sortByRTWithRealETA()`
  - 首次渲染：顯示未排序列表（或 fallback 排序）
  - 背景查詢：批次抓取所有訂單的 `courier→merchant` 與 `merchant→customer` ETA
  - 記憶體快取：避免重複查詢相同格子對（key: `"${from}->${to}"`）
  - 查詢完成：列表重新排序（無閃爍，使用 Key 穩定）
  - 若 OSRM 表不存在：`DistanceService` 回傳 `null` → RTCalculator 使用 fallback（5分鐘）
- **R/T 公式**：
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
  - 當前狀態：查詢 `h3_distance_matrix` 表（若不存在回傳 `null`）
- **Fallback 策略**：
  - `courierToMerchantEta` 缺失 → 預設 5 分鐘
  - `merchantToCustomerEta` 缺失 → 預設 5 分鐘
  - `prepTimeMinutes` 缺失 → 預設 15 分鐘
- **實際效果**：
  - 若 OSRM 表存在且有資料：使用真實距離排序
  - 若表不存在：fallback 到 5 分鐘，排序主要依 `deliveryPrice`（R）與 `prepTime`（T 的一部分）
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
- **前端查詢**（已實作）：
  - `DistanceService.getCourierToMerchantEta(courierH3, merchantH3) -> int?`
  - `DistanceService.getMerchantToCustomerEta(merchantH3, customerH3) -> int?`
  - 查詢樣例：
    ```dart
    final response = await _client
        .from('h3_distance_matrix')
        .select('time_minutes')
        .eq('from_h3', courierH3)
        .eq('to_h3', merchantH3)
        .maybeSingle();
    return response?['time_minutes'] as int?;
    ```
  - 若表不存在或查詢失敗：回傳 `null`（觸發 RTCalculator fallback 5分鐘）
- **快取策略**（已實作）：
  - Stage1 使用簡易記憶體快取 `Map<String, int?> _etaCache`
  - Cache key: `"${from_h3}->${to_h3}"`
  - 避免重複查詢相同格子對

##### 測試
- **單元測試**（12 測試，全通過）：
  - `packages/core_data/test/rt_calculator_test.dart`（7 測試）
    - TC-COU-RT-001: 基本 R/T 計算
    - TC-COU-RT-002: 使用較大的 prepTime
    - TC-COU-RT-003: ETA 缺失時 fallback
    - TC-COU-RT-004: prepTime 缺失時 fallback (15分)
    - TC-COU-RT-005: 最小 T = 5 分鐘
    - TC-COU-RT-006: R/T 降序排序
    - TC-COU-RT-007: Tie-breaker（deliveryPrice → createdAt）
  - `packages/core_data/test/rt_calculator_with_eta_test.dart`（5 測試）
    - TC-COU-RT-ETA-001: 不同 ETA 影響排序
    - TC-COU-RT-ETA-002: 較短 merchant→customer 時間提升 R/T
    - TC-COU-RT-ETA-003: Null ETA 使用 fallback
    - TC-COU-RT-ETA-004: 混合 null 與真實 ETA
    - TC-COU-RT-ETA-005: 較高外送費補償較長 ETA

#### Stage 2：前往店家（Go to Merchant）

##### 功能實作
- **UI**：店家 icon、提示文案、地址占位
- **資料**：接收 `Order` 物件（via GoRouter extra）
- **導航**：Google Maps 導航按鈕（Toast 占位）
- **到店驗證**：「我已抵達店家」按鈕 → Toast（拍照驗證占位）→ 導覽至 Stage3

##### 暫行方案
- **店家資訊**：顯示 `merchantId.substring(0, 8)`，地址硬編碼占位
- **ETA/距離**：固定顯示「預計抵達: 5 分鐘 (1.5km)」
- **導航**：顯示 Toast「導航功能開發中」
- **到店驗證**：顯示 Toast「到店拍照驗證功能開發中」

##### 未來改進
- 整合店家真實資料（名稱、地址、聯絡方式）
- Google Maps 深連結導航
- 到店拍照上傳 Supabase Storage
- 聯絡店家（雙向遮罩保護）

#### Stage 3：店家等待（Wait for Merchant）

##### 功能實作
- **UI**：備餐時間顯示、倒數占位、聯絡店家按鈕
- **資料**：接收 `Order` 物件
- **流程**：顯示備餐時間 → 等待完成 → 進入 Stage4

##### 暫行方案
- **倒數計時**：固定顯示「剩餘時間: 10 分鐘」（未實作實際倒數）
- **聯絡店家**：Toast 占位（雙向遮罩保護功能開發中）
- **取餐驗證**：Toast 占位（取餐碼驗證功能開發中）

##### 未來改進
- 實際倒數計時器（基於 `prepTimeMinutes`）
- 取餐碼驗證流程
- 雙向遮罩通訊（電話/訊息）
- 問題通報（餐點延遲/缺貨）

#### Stage 4：前往顧客（Go to Customer）

##### 功能實作
- **UI**：顧客 icon、地址占位、導航/聯絡按鈕
- **資料**：接收 `Order` 物件
- **完成送達**：呼叫 `markDelivered()` → 返回首頁

##### 暫行方案
- **顧客資訊**：顯示 `customerId.substring(0, 8)`，地址硬編碼占位
- **ETA/距離**：固定顯示「預計抵達: 8 分鐘 (2.3km)」
- **導航**：Toast 占位
- **聯絡顧客**：Toast 占位（雙向遮罩保護）
- **完成送達**：呼叫 REST `UPDATE status = DELIVERED`

##### 未來改進
- 整合顧客真實地址
- Google Maps 深連結
- 送達拍照/簽收驗證
- 雙向遮罩通訊

---

### 4.3 服務層整合

#### OrderService
- **位置**：`packages/supabase_client/lib/src/order_service.dart`
- **方法**：
  - `acceptOrder(orderId)`: REST `UPDATE` + 樂觀鎖（`.eq('status', WAITING_COURIER)`）
  - `markDelivered(orderId)`: REST `UPDATE status = DELIVERED`
  - `getCourierHistory(courierId, from?, to?)`: 查詢已完成/取消訂單
- **TODO**：切換為 RPC（原子操作、照片/簽收驗證）

#### RealtimeService
- **當前狀態**：已實作客端 map 過濾 `WAITING_COURIER`
- **暫行方案**：h3Cell 參數可選（未實作 H3 範圍過濾）

---

### 4.4 熱度地圖（Heat Map）

#### 功能實作
- **HeatMath 計算引擎**（`packages/domain/lib/src/heat/heat_math.dart`）：
  - `computeHeatScore(waitingOrders, activeCouriers)`: S = waiting / (active + 1)
  - `normalize(value, p10, p90)`: P10/P90 正規化 → [0, 1]
  - `applyGamma(x, gamma=1.4)`: x^(1/γ) 層次強化
  - `ema(prev, current, alpha=0.2)`: 指數移動平均（時間平滑）
  - `computePercentiles(values)`: 計算 P10/P90
  - `computeFinalHeat(...)`: 完整流程（S → normalize → gamma → EMA）

- **HeatMapWidget**（`apps/courier_app/lib/features/heat/presentation/heat_map_widget.dart`）：
  - 輸入：`centerH3` (String?), `heatValues` (Map<String, double>)
  - 簡化 3x3 網格（中心 + 8 鄰居），完整 k=40 網格需 Canvas/CustomPaint
  - 顏色映射：White (0) → Yellow (0.33) → Orange (0.66) → Red (1)
  - 中心格顯示定位 icon (`my_location`)
  - 圖例：低/中/高（顏色圓點 + 文字）
  - GPS 未取得時顯示 placeholder（「取得位置中...」）

- **CurrentOrdersPage 整合**：
  - GPS→H3 初始化（同 Stage1）
  - 顯示 `HeatMapWidget` 於熱度視窗區塊
  - Mock 熱度資料（中心 0.9，鄰居 0.6）

#### 暫行方案（資料來源）
- **熱度資料**：
  - 當前為前端 mock（中心最高，鄰居次之）
  - 未查詢實際 `waitingOrders` 與 `activeCouriers` 數量
- **網格範圍**：
  - 簡化為 3x3（9 格），完整 k=40 需 81x81 或動態範圍
- **更新頻率**：
  - 當前為靜態（頁面載入時計算一次）
  - 未實作 30 秒定時更新與 EMA 平滑

#### 測試
- **單元測試**（7 測試，全通過）：
  - `packages/domain/test/heat_math_test.dart`
  - TC-COU-HEAT-001: 基本 heat score 計算
  - TC-COU-HEAT-002: P10/P90 正規化（含邊界）
  - TC-COU-HEAT-003: Gamma 曲線（monotonic）
  - TC-COU-HEAT-004: EMA 平滑
  - TC-COU-HEAT-005: P10/P90 百分位計算
  - TC-COU-HEAT-006: 完整流程（無 EMA）
  - TC-COU-HEAT-007: 完整流程（含 EMA）

#### 未來改進
- **資料來源**：
  - 後端 RPC/View 查詢 k=40 範圍內各格子的 `(waitingOrders, activeCouriers)`
  - 或 Realtime 訂閱格子統計資料
- **完整網格**：
  - 使用 Canvas/CustomPaint 繪製 k=40 完整範圍
  - 動態縮放與平移
- **即時更新**：
  - 30 秒定時器更新熱度資料
  - EMA 平滑避免閃爍（`previousHeat` 持久化）
- **互動**：
  - 點擊格子顯示該區訂單數與外送員數
  - 縮放與拖曳手勢

---

### 4.5 首次登入 KYC 流程

#### 暫行方案
- **未實作**：證件拍攝（7 項證件：身分證、駕照、行照、保險、健檢、良民證、銀行存摺）
- **未實作**：Supabase Storage 上傳
- **未實作**：審核狀態追蹤

#### 未來改進
- 拍照/選檔介面（web 支援 file picker，mobile 支援相機）
- Storage bucket: `kyc-documents/{courierId}/{document_type}.jpg`
- 審核狀態欄位與通知
- 審核駁回重新上傳流程

---

### 4.6 歷史訂單與帳號管理（History/Account）

#### History 頁面實作
- **位置**：`apps/courier_app/lib/features/history/presentation/history_page.dart`
- **功能**：
  - 篩選：時間範圍（今日/本週/本月/自訂）、狀態（DELIVERED/取消）、關鍵字搜尋
  - 列表卡片：訂單編號、完成時間、狀態標籤、餐費/外送費
  - 點擊卡片開詳情 BottomSheet（`order_details_sheet.dart`）
- **資料來源**：
  - `OrderService.getCourierHistory(courierId, from?, to?)`
  - 查詢 `orders` 表，篩選 `courier_id` 與 `status in (DELIVERED, CANCELLED_*)`
  - 時間範圍過濾：`updated_at` 欄位
  - 其餘篩選（狀態、關鍵字）：前端處理
- **UI**：
  - 全用 Design Tokens
  - 狀態標籤：已完成（綠）、已取消（紅）
  - EmptyState：「暫無訂單」

#### OrderDetailsSheet 實作
- **位置**：`apps/courier_app/lib/features/history/presentation/order_details_sheet.dart`
- **功能**：
  - DraggableScrollableSheet（可拖曳高度）
  - 顯示：訂單編號、狀態、建立/完成時間、餐點明細、價格明細（餐費/外送費/總計）
- **UI**：全用 Design Tokens，狀態標籤與 History 卡片一致

#### Account 頁面實作
- **位置**：`apps/courier_app/lib/features/account/presentation/account_page.dart`
- **功能段落**：
  1. **個人資料**：姓名、Email、車輛資訊（Toast 占位）
  2. **工作狀態**：接受新訂單開關（Toast 回饋，實際狀態未同步後端）
  3. **通知與設定**：推播通知開關（Toast 回饋）、KYC 驗證狀態（Toast 占位）、裝置安全（Toast 占位）
  4. **金融與文件**：銀行帳戶（遮罩顯示）、合約文件（Toast 占位）
  5. **幫助與支援**：幫助中心、意見回饋、關於（版本號）
  6. **登出**：確認對話框 → 呼叫 `authService.signOut()`
- **UI**：
  - 全用 Design Tokens
  - CBCard 分段
  - ListTile + Switch/Chevron
  - 登出按鈕紅色（`DesignTokens.danger`）

#### 測試
- **單元測試**（8 測試，全通過）：
  - `packages/core_data/test/courier_history_filter_test.dart`（5 測試）
    - TC-COU-HIS-001: 過濾 DELIVERED 狀態
    - TC-COU-HIS-002: 過濾取消狀態
    - TC-COU-HIS-003: 時間範圍過濾（今日）
    - TC-COU-HIS-004: 關鍵字搜尋
    - TC-COU-HIS-005: 複合過濾（狀態 + 時間）
  - `packages/core_data/test/courier_account_test.dart`（3 測試）
    - TC-COU-ACC-001: 接單開關切換
    - TC-COU-ACC-002: 推播通知切換
    - TC-COU-ACC-003: 多個開關獨立運作

#### 暫行方案與缺口
- **資料來源**：
  - History：OrderService 查詢，前端篩選（狀態、關鍵字）
  - Account：個人資料為靜態占位（未查詢 `couriers` 表或 `auth.users`）
- **狀態同步**：
  - 接單開關、推播開關：僅前端 state，未同步後端
  - 建議欄位：`couriers.is_accepting_orders` (bool), `couriers.push_enabled` (bool)
- **CSV 匯出**：未實作（可加按鈕 + Toast 占位）
- **KYC 狀態**：顯示「已完成（開發中）」，未查詢實際狀態

#### 未來改進
- **後端同步**：
  - 新增 RPC `update_courier_status(is_accepting_orders, push_enabled)`
  - 查詢 `couriers` 表取得真實個人資料
- **CSV 匯出**：
  - 後端產生 CSV（或前端 dart:io）
  - 下載/分享功能
- **KYC 整合**：
  - 查詢驗證狀態
  - 未通過時顯示警告與補件連結

---

## 已知缺口與待辦

1. **OSRM 距離資料**：
   - ✅ `DistanceService` 已實作查詢邏輯（若表存在則讀取，否則回傳 null）
   - ⚠️ `h3_distance_matrix` 表尚未建立（當前使用 fallback 5min）
   - 一旦表建立並導入資料，R/T 排序將自動使用真實 ETA
2. **R/T 排序 ETA 查詢**：
   - ✅ 已改用 `FutureBuilder` 包裝 + 記憶體快取
   - ✅ 非同步批次查詢所有訂單的 ETA
   - ⚠️ 快取策略為簡易記憶體（無持久化、無過期機制）
   - 未來可改進：LRU 快取、過期時間、預載附近格子
3. **H3 範圍過濾**：
   - ✅ 客端 k=40 過濾已實作
   - TODO: 後端 RPC/View 預過濾（減少傳輸量）
4. **GPS 即時更新**：
   - ✅ GPS→H3 已整合
   - TODO: 監聽 GPS stream，移動時重新計算範圍
5. **熱度地圖**：
   - ✅ HeatMath 完整實作
   - ✅ 3x3 網格可視化
   - TODO: 實際資料查詢、k=40 完整網格、30秒更新、互動
6. **照片驗證**：到店/送達拍照與 Storage 上傳
7. **取餐碼/簽收**：驗證流程
8. **Google Maps 導航**：深連結整合
9. **雙向遮罩通訊**：聯絡店家/顧客
10. **KYC 流程**：首次登入證件上傳（7 項證件）
11. **RPC 替代 REST**：`accept_order`/`mark_delivered` 改為 RPC
12. **整合測試**：Supabase Local 完整路徑與 RLS
13. **History/Account 後端同步**：
    - 接單開關/推播開關未同步後端
    - 個人資料為靜態占位
    - CSV 匯出未實作

---

## 後續待辦

- [x] Phase 4.1：Login 動畫
- [x] Phase 4.2：接單流程（Stage 1–4）骨架
- [x] Phase 4.2+：R/T 排序邏輯與 fallback
- [x] Phase 4.3：GPS→H3 與 k=40 範圍過濾（客端）
- [x] Phase 4.4：熱度地圖最小實作（HeatMath + 3x3 網格 + mock 資料）
- [x] Phase 4.3+：OSRM 查詢邏輯與真實 ETA 整合（表待建立）
- [x] Phase 4.6：History/Account 骨架（篩選、詳情、開關占位）
- [ ] Phase 4.3++：OSRM 表建立與資料導入
- [ ] Phase 4.4+：熱度地圖完善（實際資料查詢、k=40 完整網格、定時更新）
- [ ] Phase 4.5：KYC 流程（證件拍攝與上傳）
- [ ] Phase 4.7：照片驗證與取餐碼
- [ ] Phase 4.8：RPC 替代 REST 與整合測試
- [ ] Phase 4.9：History/Account 後端同步（狀態、個人資料、CSV 匯出）

---

**版本**：Phase 4.6 History/Account 骨架完成
**更新日期**：2025-01-15

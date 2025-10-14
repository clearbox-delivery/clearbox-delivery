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

###### 後端 Schema（已完成）
- **Migration**：`infra/supabase/migrations/20250115000000_h3_distance_matrix.sql`
- **表結構**：`h3_distance_matrix`
  - 欄位：`from_h3` (text), `to_h3` (text), `time_minutes` (int), `distance_km` (real), `created_at`, `updated_at`
  - Primary key：`(from_h3, to_h3)`
  - 索引：`idx_h3_distance_from (from_h3)`, `idx_h3_distance_to (to_h3)`
  - RLS：公開唯讀（應用層不寫入，僅 ETL 腳本）
- **RPC**：`get_batch_eta(p_pairs JSONB)`
  - 輸入：`[{from_h3, to_h3}, ...]`
  - 輸出：`TABLE(from_h3, to_h3, time_minutes)`
  - 用途：批量查詢多對 H3 pair，減少請求數

###### ETL 流程（已文件化）
- **位置**：`infra/seed/h3_distance_etl_example.md`
- **步驟**：
  1. 產生全台灣 H3 res=10 格子清單（Python h3 library）
  2. 對每格計算 k=40 範圍鄰居的 OSRM 距離（批次查詢）
  3. 產生 CSV：`from_h3, to_h3, time_minutes, distance_km`
  4. 導入 Supabase（`COPY` 或 bulk insert）
- **資料量**：約 300 萬筆（150 MB）
- **更新頻率**：週或月

###### 前端批量查詢（已實作）
- **DistanceService 增強**：
  - `getBatchETA(pairs) -> Map<String, int?>`
  - 呼叫 `get_batch_eta` RPC，批量查詢多對 H3 pair
  - 若 RPC 不可用：降級為單次查詢（或回傳 null）
- **LRU 快取**：
  - 容量：500 筆
  - TTL：30 分鐘
  - 策略：快取命中直接返回；超過容量移除最舊項目；過期自動清除
  - 負值快取：查詢不到的 pair 也快取為 `null`（避免重複查詢）

###### Stage1 批量查詢策略（已實作）
- **去重**：先收集所有訂單的 H3 pair，去重後批量查詢（減少請求數）
- **流程**：
  1. 收集 unique pairs（courier→merchant, merchant→customer）
  2. 呼叫 `getBatchETA(pairs)`（LRU 快取優先）
  3. 將 ETA map 傳入 `RTCalculator.sortByRT()`
  4. 若任何 ETA 為 null：使用 fallback（5分鐘）
- **效能**：
  - 20 筆訂單、無快取命中：約 2-4 個 RPC 請求（每次最多查 100 對）
  - 有快取命中：0-1 個請求
  - 查詢時間：5-20ms（取決於資料量與快取率）

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

#### OrderService（已升級為 RPC）
- **位置**：`packages/supabase_client/lib/src/order_service.dart`
- **方法**：
  - `acceptOrder(orderId)`: 呼叫 RPC `accept_order`（原子操作 + 衝突處理）
  - `markDelivered(orderId, deliveryPhotoUrl?)`: 呼叫 RPC `mark_delivered`（含 courier 驗證）
  - `getCourierHistory(courierId, from?, to?)`: 查詢已完成/取消訂單

#### Courier RPCs（已實作）
- **Migration**：`infra/supabase/migrations/20250115000002_courier_rpcs.sql`
- **accept_order(p_order_id UUID)**：
  - 原子更新：`status = COURIER_ASSIGNED`, `courier_id = auth.uid()`
  - 樂觀鎖：僅當 `status = WAITING_COURIER AND courier_id IS NULL`
  - 返回：`{success: bool, order?: object, error_code?: string, message?: string}`
  - 錯誤碼：`ERR_ALREADY_ASSIGNED`（訂單已被接單或不可用）
- **mark_delivered(p_order_id UUID, p_delivery_photo_url TEXT)**：
  - 驗證：僅 assigned courier 可標記
  - 狀態檢查：僅 `PICKED_UP/DELIVERING` 可標記
  - 返回：`{success: bool, order?: object, error_code?: string, message?: string}`
  - 錯誤碼：`ERR_INVALID_STATE`（訂單狀態不正確或非本人）

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

#### 功能實作
- **KYCFlowPage**（`apps/courier_app/lib/features/kyc/presentation/kyc_flow_page.dart`）：
  - Stepper 流程（9 步驟，不可跳過）：
    1. 真實姓名輸入
    2. 身分證正面拍攝
    3. 身分證反面拍攝
    4. 正面自拍
    5. 機車駕照拍攝
    6. 機車行照拍攝
    7. 良民證拍攝
    8. 銀行帳簿拍攝 + 帳號輸入
    9. 保溫袋 Logo 拍攝
  - 每步驗證：姓名非空、證件已上傳、銀行帳號非空
  - 完成後導覽至 `/current-orders`
  - UI 全用 Design Tokens，Stepper + CBButton + CBInput

- **StorageService**（`packages/supabase_client/lib/src/storage_service.dart`）：
  - `uploadKYCDocument(courierId, documentType, fileBytes)`: 上傳 KYC 證件
  - `uploadOrderPhoto(orderId, photoType, fileBytes)`: 上傳訂單照片（到店/送達）
  - `uploadMenuPhoto(merchantId, itemId, fileBytes)`: 上傳菜單照片
  - Bucket 規劃：
    - `kyc-documents/{courierId}/{documentType}.jpg`
    - `order-photos/{orderId}/{photoType}.jpg`
    - `menu-photos/{merchantId}/{itemId}.jpg`

#### 實作狀態（拍照/上傳）
- **拍照功能**（已實作）：
  - Web：`FilePicker.platform.pickFiles(type: FileType.image)`
  - Mobile：`ImagePicker.pickImage(source: camera/gallery)`
  - 對話框選擇：拍照 vs 從相簿選擇
  - 讀取 bytes 與副檔名
- **StorageService**（已實作）：
  - `storage.from('kyc-documents').uploadBinary(path, fileBytes)`
  - FileOptions: `upsert: true`, `contentType: image/*`
  - 回傳 public URL
  - 錯誤處理：bucket 不存在時回傳 null（UI 顯示錯誤 Toast）
- **上傳流程**：
  - 選擇/拍攝照片 → Toast「上傳中...」→ 呼叫 StorageService
  - 成功：更新 state + Toast「上傳成功」+ 顯示綠色 check icon
  - 失敗：Toast「上傳失敗，請重試（Storage bucket 可能尚未建立）」

#### Storage Bucket 實作（已完成）
- **Migration**：`infra/supabase/migrations/20250115000001_storage_buckets.sql`
- **kyc-documents**（KYC 證件）：
  - 路徑：`{courierId}/{documentType}.{ext}`
  - 大小限制：5MB
  - MIME types：`image/jpeg`, `image/png`, `image/jpg`
  - RLS：
    - INSERT: Couriers can upload to own folder (`foldername[1] = auth.uid()`)
    - SELECT: Couriers can read own documents
    - UPDATE: Couriers can update own documents
    - TODO: Admin role policy for reading all
  - 用途：審核外送員資格
- **order-photos**（訂單照片）：
  - 路徑：`{orderId}/{photoType}.jpg`
  - 大小限制：10MB
  - RLS：
    - INSERT: Courier assigned to order can upload
    - SELECT: Order participants (courier/merchant/customer) can read
  - 用途：到店驗證、送達驗證
- **menu-photos**（菜單照片）：
  - 路徑：`{merchantId}/{itemId}.jpg`
  - 大小限制：5MB
  - Public：true（公開可讀）
  - RLS：
    - INSERT/UPDATE: Merchant owns the folder
    - SELECT: Public
  - 用途：菜單品項展示

#### 測試
- **單元測試**（5 測試，全通過）：
  - `packages/core_data/test/kyc_validation_test.dart`
  - TC-COU-KYC-001: 姓名必填
  - TC-COU-KYC-002: 全部 8 項證件必填
  - TC-COU-KYC-003: 銀行帳號必填
  - TC-COU-KYC-004: 證件類型驗證
  - TC-COU-KYC-005: 步驟進退驗證

#### 未來改進
- **圖片優化**：
  - 壓縮與裁切（`image` package）
  - 自動旋轉與方向校正
  - 縮圖產生（加速載入）
- **審核狀態**：
  - `couriers` 表新增 `kyc_status` 欄位（pending/approved/rejected）
  - `kyc_documents` 表記錄所有上傳檔案（URL、上傳時間、審核狀態）
  - 審核駁回通知與重新上傳流程
  - Account 頁顯示審核狀態與進度
- **安全性**：
  - 照片加浮水印（防盜用）
  - 敏感資料模糊處理（顯示時）
  - 審核後自動刪除或移至歸檔 bucket
  - 管理員角色 RLS policy
- **UX 優化**：
  - 上傳進度條
  - 照片預覽與重拍
  - 批量上傳（多張一次）

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
   - ✅ Migration 已建立（`20250115000000_h3_distance_matrix.sql`）
   - ✅ `DistanceService` 批量查詢與 LRU 快取（500 筆、30 分鐘 TTL）
   - ✅ `get_batch_eta` RPC 已定義
   - ⚠️ 資料尚未導入（ETL 腳本已提供於 `infra/seed/h3_distance_etl_example.md`）
   - 一旦資料導入，R/T 排序將自動使用真實 ETA
2. **R/T 排序批量查詢**：
   - ✅ Stage1 已升級為批量查詢 + H3 pair 去重
   - ✅ LRU 快取（容量、TTL、負值快取）
   - ✅ 降級策略：RPC 失敗時回傳 null（觸發 fallback）
   - 可選改進：預載附近 k=40 所有 pairs（啟動時）
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
10. **KYC 流程**：
    - ✅ 流程骨架、真實上傳、Storage buckets + RLS
    - TODO: 審核狀態（kyc_status/kyc_documents）、壓縮/進度條、管理員 RLS
11. **RPC 替代 REST**：
    - ✅ `accept_order`/`mark_delivered` RPC 已實作並接線
    - ✅ 錯誤碼與衝突處理
    - TODO: 其他 RPCs（merchant_confirm 等已有，可檢視是否需優化）
12. **整合測試**：
    - ✅ 測試骨架已建立（`tests/integration/courier_rpc_test.dart`）
    - ⚠️ 標記 skip（需 Supabase Local 與測試資料）
    - 文件化前置條件：supabase start、migrations、測試 JWT
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
- [x] Phase 4.3+：OSRM 查詢邏輯與真實 ETA 整合
- [x] Phase 4.3++：OSRM Migration + 批量查詢 + LRU 快取 + ETL 文件
- [x] Phase 4.6：History/Account 骨架（篩選、詳情、開關占位）
- [x] Phase 4.5：KYC 流程骨架（Stepper + Storage 規劃 + 占位上傳）
- [x] Phase 4.5+：KYC Storage 整合（file_picker/image_picker + 真實上傳 + RLS）
- [x] Phase 4.8：RPC 替代 REST（accept_order/mark_delivered 原子化）
- [x] Phase 4.8+：整合測試骨架（Supabase Local 前置條件文件化）
- [ ] Phase 4.3+++：OSRM 資料導入（由管理員執行 ETL，導入 300 萬筆）
- [ ] Phase 4.4+：熱度地圖完善（實際資料查詢、k=40 完整網格、定時更新）
- [ ] Phase 4.5++：KYC 審核狀態（kyc_status/kyc_documents、壓縮/進度條）
- [ ] Phase 4.7：照片驗證與取餐碼（到店/送達驗證流程）
- [ ] Phase 4.9：History/Account 後端同步（狀態、個人資料、CSV 匯出）

---

**版本**：Phase 4.8 RPC + 整合測試骨架完成
**更新日期**：2025-01-15

# Phase 3 實作說明與最小差異

本文件記錄 Phase 3（Merchant App - Current Orders）實作過程中的暫行方案與待改進項目。

## 最小差異說明

### 3.3 Preparing（備餐中）分頁

#### 外送員資訊顯示
- **暫行方案**：
  - 外送員暱稱：顯示 `courierId` 前 6 碼（例：`外送員a3f4b2`）
  - 評分：固定顯示 `4.8`
  - 近七日完成單數：固定顯示 `32 單`
  - 交通工具：固定顯示 `機車`
- **未來改進**：
  - 完整外送員 Profile（含真實暱稱、頭像、評分統計）
  - 從 `user_profiles` 或 `couriers` 表關聯查詢
  - 動態計算近七日完成訂單數

#### 到店 ETA 與距離
- **暫行方案**：
  - ETA：固定顯示 `5 分鐘`
  - 距離：固定顯示 `1.2km`
- **未來改進**：
  - 整合外送員即時位置（GPS）
  - 使用路線規劃 API（Google Maps Directions / OpenStreetMap）計算實際 ETA
  - H3 距離估算作為後備方案

#### 承諾取餐時間計算
- **暫行方案**：
  - 使用 `created_at + prep_time_minutes` 計算
  - 程式碼位置：`preparing_tab.dart` 第 276-281 行
  ```dart
  DateTime _calculatePromisedTime(Order order) {
    // TODO: Should use actual accepted_at timestamp from events
    final prepMinutes = order.prepTimeMinutes ?? 15;
    return order.createdAt.add(Duration(minutes: prepMinutes));
  }
  ```
- **未來改進**：
  - 從 `order_events` 查詢 `COURIER_ACCEPTED` 事件的 `created_at` 作為接單時間
  - 使用 Event Sourcing 重建時間軸：`接單時間 + prep_time_minutes = 承諾取餐時間`
  - 考慮動態調整（如商家多次延長備餐時間）

#### 逾時檢測
- **當前邏輯**：
  - 若 `DateTime.now() > 承諾取餐時間`，顯示紅色逾時條
  - 計算延誤分鐘數：`DateTime.now().difference(promisedTime).inMinutes`
- **準確度影響**：
  - 因承諾時間基於 `created_at`（而非接單時間），可能早於實際約定時間
  - 建議在外送員接單功能完整後，改用正確的接單時間戳

---

### 3.4 Picked-up（已取貨）分頁

#### 外送員資訊顯示
- **暫行方案**：
  - 外送員暱稱：顯示 `courierId` 前 6 碼（例：`外送員b4c5d3`）
  - 評分：固定顯示 `4.9`
  - 近七日完成單數：固定顯示 `28 單`
  - 交通工具：固定顯示 `機車`
- **未來改進**：同 Preparing 分頁

#### 送達 ETA 與距離
- **暫行方案**：
  - 送達 ETA：固定顯示 `8 分鐘`
  - 距離：固定顯示 `2.1km`
- **未來改進**：
  - 整合外送員即時位置（GPS）與顧客地址
  - 使用路線規劃 API 計算實際送達 ETA
  - H3 距離估算作為後備方案

#### 顧客收件區域顯示
- **暫行方案**：
  - 固定顯示 `信義區松仁路段`（隱私保護，僅顯示里/路段）
  - 程式碼位置：`picked_up_tab.dart` 第 234-238 行
  ```dart
  String _getDeliveryArea() {
    // TODO: Extract from customer address when available
    return '信義區松仁路段';
  }
  ```
- **未來改進**：
  - 從 `customer_addresses` 表提取實際區域資訊
  - 自動脫敏處理（僅保留里/路段）
  - 考慮地址隱私政策與法規要求

#### 聯絡功能
- **暫行方案**：
  - 「聯絡外送員」與「聯絡顧客」皆為占位 Toast 提示
  - 「查看路線」與「問題通報」同為占位 UI
- **未來改進**：
  - 雙向遮罩電話（Twilio / 自建中繼號碼）
  - 即時訊息系統（僅限訂單相關溝通）
  - 路線地圖整合（Google Maps / OpenStreetMap）
  - 問題通報工單系統（分類：取錯、遺漏、其他）

#### 狀態推進
- **當前邏輯**：
  - 本分頁不提供任何狀態更新 RPC（由外送員端推進至 DELIVERED）
  - 僅提供監控與聯絡功能
- **未來擴充**：
  - 顧客端退單/申訴流程
  - 商家端重大問題上報（需平台介入）

---

### 3.5 MenuManagement（菜單管理）CRUD 骨架

本階段實作三級架構 UI 骨架（Categories → Items → Edit Item），暫行使用本地狀態與 mock 資料，後續需整合後端與 DB。

#### 資料來源
- **暫行方案**：
  - 類別、品項資料皆為前端 mock（`List<Map<String, dynamic>>`）
  - 排序、上下架狀態僅存於 UI state，重新載入後復原
  - 照片上傳僅為占位 UI（灰底 + icon）
- **未來改進**：
  - 建立 `menu_categories` 與 `menu_items` 表（含 `merchant_id`, `sort_order`, `is_visible`, `photo_url`, `volume_level`, `weight_level`, `prep_time_minutes`, `stock`, `auto_off_on_sold_out` 等欄位）
  - 整合 Supabase Storage 上傳照片
  - 實作 RPC: `create_menu_item`, `update_menu_item`, `delete_menu_item`, `reorder_categories`

#### 路由架構
- `/menu`：類別列表（CategoriesPage）
- `/menu/items`：品項列表（ItemsPage，傳入 category extra）
- `/menu/items/edit`：編輯品項（EditItemPage，傳入 category + item extra）

#### Categories（類別管理）
- **功能**：
  - 列表顯示類別名稱、品項數量、可見開關
  - 拖拉排序（`ReorderableListView`）
  - 新增、重新命名、刪除類別
  - 上架/下架切換（Switch）
- **暫行限制**：
  - 拖拉排序僅更新 UI，不持久化（Toast 提示「待後端實作」）
  - 刪除類別無級聯檢查（未來需檢查是否有品項）

#### Items（品項清單）
- **功能**：
  - 顯示縮圖（占位）、名稱、價格、上架狀態、庫存、備餐時間、容量/重量等級標籤
  - 批次選擇模式（Checkbox + 批次刪除）
  - 上下架切換（Switch）
  - 點擊進入編輯
- **暫行限制**：
  - 縮圖固定為灰底 icon
  - 批次操作（移動到其他類別、複製）未實作
  - 篩選/搜尋功能未實作

#### Edit Item（品項編輯）
- **功能**：
  - 基本資訊：名稱、說明、價格
  - 備餐資訊：預設備餐時間（分鐘）
  - 容量/重量等級：V1-V4 / W1-W4（RadioListTile）
  - 庫存管理：每日可售數、售罄自動下架開關
  - 上架狀態：立即上架 Switch
  - 照片上傳：占位 UI（開發中）
  - 選配/加購：占位 UI（開發中）
- **暫行限制**：
  - 照片上傳未整合 Storage
  - 選配/加購（單選/多選、加價金額）僅顯示占位卡片
  - 預覽「顧客端呈現」未實作
  - 離開未存提示（unsaved changes warning）未實作
- **驗證邏輯**：
  - 名稱不可空
  - 價格必須為正數
  - 備餐時間必須為正整數
- **儲存行為**：
  - 前端驗證通過後顯示 Loading，延遲 1 秒模擬儲存，回到上一頁並顯示 Toast

#### 店家營業狀態聯動
- **未實作**：
  - 「暫停點餐」總開關
  - 營業時間外自動禁止新單
  - 手動暫停/恢復
- **未來位置**：Account 頁面 > 營業與接單區塊

---

### 3.5+ MenuManagement 後端整合（Phase 3.5+）

本階段將 UI 骨架接線至 Supabase 後端，使用 REST API 進行資料操作。

#### 資料表與欄位
- **期望表結構**：`menu_items`
  - 欄位：`id`, `merchant_id`, `category`, `name`, `description`, `price`, `image_url`, `volume_level`, `weight_level`, `prep_time_minutes`, `stock_quantity`, `is_available`, `created_at`, `updated_at`
- **當前狀態**：表結構存在，MenuItem 模型已完整對應
- **RLS 策略**：需確保商家僅能操作自己的品項（`merchant_id = auth.uid()`）

#### 服務層實作
- **位置**：`packages/supabase_client/lib/src/menu_service.dart`
- **方法**：
  - `getMenuByCategory(merchantId)`: REST SELECT，取得所有品項（含未上架）
  - `getCategories(merchantId)`: 客端分組統計
  - `createMenuItem(...)`: REST INSERT（TODO: 後續改為 RPC 強化驗證）
  - `updateMenuItem(...)`: REST UPDATE（TODO: 後續改為 RPC）
  - `deleteMenuItem(itemId)`: REST DELETE（TODO: 後續改為 RPC）
- **暫行方案**：
  - 使用 REST API 直接操作 `menu_items` 表
  - 類別（category）為字串欄位，無獨立表
  - 類別可見性（isVisible）暫不持久化，前端固定 `true`

#### UI 接線
- **CategoriesPage**：
  - 從 `getCategories()` 獲取類別列表（按品項分組）
  - 排序拖拉：顯示「待後端實作」Toast（TODO: 需後端 `sort_order` 欄位）
  - 重新命名：顯示「待後端實作」Toast（TODO: 需獨立 `menu_categories` 表或批次更新品項）
- **ItemsPage**：
  - 從 `getMenuByCategory()` 獲取當前類別品項
  - 上下架切換：呼叫 `updateMenuItem(isAvailable)`
  - 批次刪除：迴圈呼叫 `deleteMenuItem()`
  - Loading/Error/Toast 完整回饋
- **EditItemPage**：
  - 新增：呼叫 `createMenuItem()`，需 merchantId
  - 編輯：呼叫 `updateMenuItem()`，更新所有可編輯欄位
  - 刪除：呼叫 `deleteMenuItem()`
  - 前端驗證：名稱不可空、price > 0、prepTime > 0、stock >= 0

#### 照片上傳
- **暫行方案**：
  - EditItemPage 保留占位 UI（灰底 + icon）
  - `imageUrl` 欄位可寫入，但前端未實作上傳
- **未來改進**：
  - Supabase Storage bucket: `menu-photos/{merchantId}/{itemId}.jpg`
  - Web/dev: file picker → upload to Storage → 取得 public URL → 更新 `imageUrl`
  - 產線：同上，加入圖片壓縮與尺寸限制

#### 選配/加購
- **暫行方案**：
  - EditItemPage 僅顯示占位卡片（「開發中」）
- **未來改進**：
  - 新增 `menu_item_options` 表（itemId, type, name, price, isRequired, minSelection, maxSelection）
  - UI：動態新增/刪除選項，設定必選/可選/加價
  - 訂單邏輯：整合選項至 `order_items` 結構

#### Realtime 更新
- **暫行方案**：
  - 頁面使用 `FutureBuilder` + 手動刷新（AppBar refresh 按鈕 / setState）
  - 未實作 Realtime 監聽 `menu_items` 表
- **未來改進**：
  - 使用 `StreamBuilder` + `RealtimeService.watchMenuItems(merchantId)`
  - 客端 map 過濾維持相容性

#### 測試
- **單元測試**（7 測試，全通過）：
  - `packages/core_data/test/menu_item_validation_test.dart`
  - TC-MER-MENU-VAL-001: 名稱必填
  - TC-MER-MENU-VAL-002: 價格 > 0
  - TC-MER-MENU-VAL-003: 備餐時間 > 0
  - TC-MER-MENU-VAL-004: 庫存 >= 0
  - TC-MER-MENU-VAL-005: 完整有效資料
  - TC-MER-MENU-VAL-006: 體積等級 V1-V4
  - TC-MER-MENU-VAL-007: 重量等級 W1-W4
- **整合測試**（待實作）：
  - TODO: 使用 Supabase Local 測試 CRUD 路徑
  - TODO: RLS 負例（otherMerchantJwt 操作他人品項應失敗）
  - 前置條件：Supabase Local 需有 `menu_items` 表與 RLS

#### 已知缺口與待辦
1. **RPC 替代 REST**：目前使用 REST INSERT/UPDATE/DELETE，後續可改 RPC 強化驗證與事務
2. **類別管理**：無獨立 `menu_categories` 表，類別由品項 category 欄位推導；排序/重新命名需後端支援
3. **照片上傳**：前端未實作 Storage 上傳流程
4. **選配/加購**：UI 占位，無 DB schema
5. **Realtime**：未實作即時監聽，依賴手動刷新
6. **整合測試**：待 schema 確認後補齊

---

### 3.6 History/Account（最小差異）

本階段實作 Merchant History 與 Account 頁面骨架，對齊白皮書必要欄位，部分功能以占位處理。

#### History（歷史訂單）

##### 功能實作
- **時間範圍篩選**：今日/本週/本月（Chip 切換）
  - 使用 `OrderService.getHistoricalOrders(merchantId, timeRange)`
  - 查詢歷史狀態：DELIVERED, CANCELLED_*, EXPIRED_UNMATCHED
- **狀態篩選**：已完成/已取消（ChoiceChip）
  - 客端過濾 `OrderStatus`
- **搜尋**：訂單編號部分匹配（客端 `contains`）
- **列表卡片**：編號（前 8 碼）、下單時間、狀態標籤、餐費、外送費
- **詳情 Sheet**：基本資訊、餐點明細、備註、時間軸占位、問題申訴/聯絡客服占位

##### 暫行方案
- **CSV 匯出**：按鈕占位 + Toast（「開發中」）
- **時間軸**：OrderDetailsSheet 顯示占位文案（「需整合 order_events 表」）
  - 未實作 `getOrderEvents` 的前端顯示
- **總時長**：未計算（下單→送達），卡片未顯示
- **付款方式**：Order 模型缺 `payment_method` 欄位，詳情未顯示
- **顧客暱稱**：Order 模型未關聯 customer profile，卡片未顯示
- **品項關鍵字搜尋**：未實作（僅支援訂單編號）

##### 未來改進
- 整合 `order_events` 表顯示完整時間軸
- CSV 匯出邏輯與檔案下載
- 計算總時長（`completed_at - created_at`）
- Order 模型擴充關聯欄位（customer_name, payment_method）
- 進階搜尋（品項關鍵字、顧客暱稱）

#### Account（帳號管理）

##### 功能實作（分段占位）
- **8.1 店家資料**：
  - 基本資料：Toast 占位（「編輯功能開發中」）
  - 驗證狀態：Toast 占位
  - 顧客端預覽：Toast 占位
- **8.2 營業與接單**：
  - 營業狀態 Switch：本地 state，切換顯示 Toast（「已切換為營業中/休息中」）
  - 接受外送訂單 Switch：本地 state，切換顯示 Toast（「已恢復接單/已暫停接單」）
  - 營業時間設定：Toast 占位
- **8.3 通知與裝置**：
  - 推播通知：Toast 占位
  - 裝置安全：Toast 占位
- **8.4 金融與文件**：
  - 收款帳戶：Toast 占位
  - 文件管理：Toast 占位
- **8.5 其他**：
  - 常見問題：Toast 占位
  - 聯絡客服：Toast 占位
  - 問題回報：Toast 占位
  - 系統資訊：AlertDialog（版本 1.0.0、建置日期、環境）
  - 清除快取：AlertDialog 確認 → Toast（「快取已清除」）
  - 登出：AlertDialog 確認 → 呼叫 `authService.signOut()` → Toast

##### 暫行方案
- **營業狀態/接單開關**：
  - 僅更新本地 state，不持久化至後端
  - Toast 回饋，未實際影響訂單可見性
- **所有子功能**：
  - 除登出/清除快取/系統資訊外，皆為 Toast 占位
  - 未整合實際資料查詢或寫入
- **底部導航索引**：Account 為 index 3（需與 AppBottomNav 對齊）

##### 未來改進
- 建立 `merchant_profiles` 表儲存基本資料、營業時間、驗證狀態
- 營業狀態/接單開關持久化至後端，影響顧客端可見性
- 推播通知設定整合 FCM/Supabase Realtime
- 裝置安全整合 `user_devices` 表
- 金融帳戶管理與遮罩顯示
- 文件上傳與審核狀態追蹤

#### 測試
- **單元測試**（5 測試，全通過）：
  - `packages/core_data/test/merchant_history_filter_test.dart`
  - TC-MER-HIS-FILTER-001: 歷史訂單狀態過濾
  - TC-MER-HIS-FILTER-002: 今日時間範圍
  - TC-MER-HIS-FILTER-003: 本週時間範圍
  - TC-MER-HIS-FILTER-004: 訂單編號搜尋
  - TC-MER-HIS-FILTER-005: 狀態+時間複合過濾
- **整合測試**（待實作）：
  - TODO: 使用 Supabase Local 測試 `getHistoricalOrders` RLS
  - 前置條件：測試資料含不同 merchant_id 與狀態的訂單

#### 已知缺口
1. **CSV 匯出**：前端未實作下載邏輯
2. **時間軸顯示**：未整合 `order_events` 至詳情 UI
3. **總時長計算**：Order 模型缺 `completed_at` 欄位
4. **顧客資訊**：Order 未關聯 customer profile（暱稱）
5. **付款方式**：Order 模型缺 `payment_method` 欄位
6. **Account 持久化**：營業狀態/接單開關僅為本地 state
7. **Account 子功能**：所有編輯/設定功能皆為占位

---

## 後續待辦

- [x] Phase 3.4：完成「已取貨（Picked-up）」分頁
- [x] Phase 3.5：MenuManagement（菜單管理）CRUD 骨架（UI + mock 資料）
- [x] Phase 3.5+：MenuManagement 後端整合（REST API + 測試）
- [x] Phase 3.6：History/Account 頁面骨架
- [ ] Phase 3.5++：MenuManagement 完善（RPC/Storage/Realtime/整合測試）
- [ ] Phase 3.6+：History/Account 後端整合（profiles/settings/完整時間軸）
- [ ] Phase 4：Courier App 完整實作
- [ ] 外送員 Profile 關聯查詢與顯示
- [ ] 即時位置與 ETA 計算整合
- [ ] Event Sourcing 時間軸重建與前端顯示
- [ ] 雙向遮罩通訊系統
- [ ] 路線地圖與問題通報工單
- [ ] 菜單照片上傳（Supabase Storage）
- [ ] 選配/加購管理 UI 與邏輯
- [ ] 店家營業狀態總開關與時段控制
- [ ] 類別獨立表與排序/可見性持久化
- [ ] CSV 匯出邏輯與下載
- [ ] Order 模型擴充（completed_at, payment_method, 關聯 profiles）

---

**版本**：Phase 3.6 History/Account 骨架完成
**更新日期**：2025-01-15


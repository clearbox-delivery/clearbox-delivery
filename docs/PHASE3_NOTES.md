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

## 後續待辦

- [x] Phase 3.4：完成「已取貨（Picked-up）」分頁
- [x] Phase 3.5：MenuManagement（菜單管理）CRUD 骨架（UI + mock 資料）
- [x] Phase 3.5+：MenuManagement 後端整合（REST API + 測試）
- [ ] Phase 3.5++：MenuManagement 完善（RPC/Storage/Realtime/整合測試）
- [ ] Phase 3.6：History/Account 頁面
- [ ] Phase 4：Courier App 完整實作
- [ ] 外送員 Profile 關聯查詢與顯示
- [ ] 即時位置與 ETA 計算整合
- [ ] Event Sourcing 時間軸重建
- [ ] 雙向遮罩通訊系統
- [ ] 路線地圖與問題通報工單
- [ ] 菜單照片上傳（Supabase Storage）
- [ ] 選配/加購管理 UI 與邏輯
- [ ] 店家營業狀態總開關與時段控制
- [ ] 類別獨立表與排序/可見性持久化

---

**版本**：Phase 3.5+ MenuManagement 後端整合完成  
**更新日期**：2025-01-15


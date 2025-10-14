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

## 後續待辦

- [ ] Phase 3.4：完成「已取貨（Picked-up）」分頁
- [ ] Phase 3.5：MenuManagement（菜單管理）CRUD 完整實作
- [ ] Phase 3.6：History/Account 頁面
- [ ] Phase 4：Courier App 完整實作
- [ ] 外送員 Profile 關聯查詢與顯示
- [ ] 即時位置與 ETA 計算整合
- [ ] Event Sourcing 時間軸重建

---

**版本**：Phase 3.3 Preparing 分頁驗收修正  
**更新日期**：2025-01-15


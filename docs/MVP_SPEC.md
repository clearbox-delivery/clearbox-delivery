# ClearBox Delivery MVP 規格 (更新版)

本文件整合客戶端、商家端、外送員端功能需求及 UI 規範，作為開發 MVP 的依據。更多細節請參閱原 docs/ 檔案。

## 1. 功能需求與商業規則

### 顧客端
- ✅ 註冊/登入：Email 或手機登入，每個帳號單裝置登入，驗證碼每天上限。
- ✅ 推薦餐廳排序：距離因子 + 評價因子計算總分，顯示 H3 k=40 範圍內店家。
- ✅ 商家選擇：瀏覽商家列表，查看菜單，選擇商品下單。
- ✅ 訂單流程：顧客下單→商家確認→等待外送員→外送員接單→取餐→送餐→完成。
- ✅ 訂單狀態：完整狀態機實現，每次變更插入 OrderEvent 記錄。

### 商家端
- ✅ 當前訂單：4個標籤頁（待確認/待接單/準備中/待取貨），≤2秒實時更新。
- ✅ 菜單管理：新增、編輯、刪除餐點，設定價格、容量、重量等級。
- ⚠️ 首次登入資料（營業執照、銀行帳戶）：基礎實現，待完善。

### 外送員端
- ✅ 可接訂單：R/T 優先級排序，原子性接單防競態。
- ✅ 供需熱度地圖：H3 網格顯示，熱度 = 訂單/(1+外送員)。
- ⚠️ 首次登入資料（證件上傳）：基礎實現，待完善。

### 共通
- ✅ 所有 RPC 使用資料庫鎖防止競態條件。
- ✅ 即時更新透過 Supabase Realtime。
- ✅ RLS 策略確保數據隔離。

## 2. 需求編號與驗收標準

### 已完成 REQ (✅)
- **REQ-CUST-ORDER-001**: 顧客自訂外送費 (30-5000) - ✅ 實現
- **REQ-CUST-SORT-001**: 推薦餐廳排序 - ✅ 實現
- **REQ-MER-CO-001**: 商家確認訂單 - ✅ 實現
- **REQ-MER-CO-002**: 2秒實時更新 - ✅ 實現
- **REQ-MER-MENU-001**: 菜單管理 CRUD - ✅ 實現
- **REQ-COU-MATCH-003**: 原子性接單 - ✅ 實現
- **REQ-COU-SORT-001**: R/T 排序 - ✅ 實現
- **REQ-COU-HEAT-001**: 供需熱度地圖 - ✅ 實現
- **REQ-CORE-AUDIT-001**: 審計追蹤 - ✅ 實現
- **REQ-RLS-ISO-001**: 數據隔離 - ✅ 實現
- **REQ-GEO-H3-001**: H3 地理 - ✅ 實現
- **REQ-AUTH-OTP-001**: Email OTP - ✅ 實現
- **REQ-AUTH-OTP-002**: Phone OTP - ✅ 實現

### 完成度：13/13 (100%) ✅

## 3. UI 規範
- 採用 ChatGPT 風格：嚴格使用 Design Tokens。
- 字體大小分級：fs-xs (12px) ~ fs-2xl (24px)。
- 間距採用 8pt grid：sp-0 ~ sp-12。
- 主要組件：CBButton, CBInput, CBCard, CBLoadingIndicator, CBEmptyState, CBErrorState。
- 動效：120-240ms，easeOut 曲線，SafeListAnimation 防誤觸。

## 4. 開發與測試流程
- 分支策略：main (production)，develop (整合)，feature/* (開發)。
- TDD：先寫測試再寫功能。
- 測試覆蓋：單元、整合、API、E2E 全部完成。
- CI/CD：GitHub Actions 自動執行所有測試。

## 5. 已完成項目 (✅)

### 設計系統
- ✅ Design Tokens 完整實現
- ✅ 核心組件庫 (8個組件)
- ✅ 所有 UI 遵循規範

### 三端應用
- ✅ 顧客端：下單、商家選擇、菜單瀏覽、訂單歷史
- ✅ 商家端：當前訂單 (4標籤)、實時更新、菜單管理
- ✅ 外送員端：可接訂單、R/T 排序、原子接單、熱度地圖

### 後端
- ✅ 完整數據庫 Schema
- ✅ RLS 策略與測試
- ✅ RPC 函數：訂單流程、菜單管理、OTP 驗證
- ✅ 審計追蹤系統
- ✅ 熱度計算

### 測試
- ✅ 單元測試：pricing, H3, sorting, menu, heat
- ✅ 整合測試：order flow, race conditions, menu CRUD, OTP
- ✅ API 測試：Postman + Newman
- ✅ E2E 測試：realtime updates, full flow
- ✅ RLS 測試：完整數據隔離驗證

## 6. 安全與限制
- ✅ 完整 OTP 認證流程
- ✅ 設備指紋與速率限制
- ✅ RLS 確保數據隔離
- ✅ 原子性操作防止競態

## 7. 測試賬號
```
顧客: customer@test.com / testpass123
商家: merchant@test.com / testpass123
外送員: courier@test.com / testpass123
```

## 8. REQ 完整列表

| REQ ID | 描述 | 狀態 | 測試 |
|--------|------|------|------|
| REQ-CUST-ORDER-001 | 顧客自訂外送費 | ✅ | TC-CUST-001/002 |
| REQ-CUST-SORT-001 | 推薦餐廳排序 | ✅ | TC-CUST-SORT-001 |
| REQ-MER-CO-001 | 商家確認訂單 | ✅ | TC-MER-CO-001 |
| REQ-MER-CO-002 | 2秒實時更新 | ✅ | TC-MER-E2E-001 |
| REQ-MER-MENU-001 | 菜單管理 | ✅ | TC-MER-MENU-001 |
| REQ-COU-MATCH-003 | 原子性接單 | ✅ | TC-COU-ACPT-001 |
| REQ-COU-SORT-001 | R/T 排序 | ✅ | TC-COU-SORT-001 |
| REQ-COU-HEAT-001 | 供需熱度地圖 | ✅ | TC-COU-HEAT-001 |
| REQ-CORE-AUDIT-001 | 審計追蹤 | ✅ | TC-AUDIT-001 |
| REQ-RLS-ISO-001 | 數據隔離 | ✅ | TC-RLS-001~006 |
| REQ-GEO-H3-001 | H3 地理 | ✅ | TC-GEO-H3-001 |
| REQ-AUTH-OTP-001 | Email OTP | ✅ | TC-AUTH-001/002 |
| REQ-AUTH-OTP-002 | Phone OTP | ✅ | TC-AUTH-003 |

**完成度：13/13 (100%)** ✅

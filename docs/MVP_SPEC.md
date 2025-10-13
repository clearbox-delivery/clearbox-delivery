# ClearBox Delivery MVP 規格

本文件整合客戶端、商家端、外送員端功能需求及 UI 規範，作為開發 MVP 的依據。更多細節請參閱原 docs/ 檔案。

## 1. 功能需求與商業規則
### 顧客端
- 註冊/ 登入：Email 或手機登入，每個帳號單裝程從登入，驗證碼每天 5 次上限。
- 推薦餐廳排序：距離因子 + 評價因子計算總分，顯示 H3 k=40 範圍內店家。
- 訂單流程：顧客下單→商家確認→等待外送員→外送員接單→取餐→送餐→完成。
- 訂單狀態：DRAFT, PENDING_STORE_CONFIRM, WAITING_COURIER, COURIER_ASSIGNED, PREPARING, PICKED_UP, DELIVERING, DELIVERED, CANCELLED, CLOSED。每次變更插入 OrderEvent 記錄。

### 商家端
- 首次登入需填寫店家資料、營業執照、銀行帳戶、建構菜單。
- 訂單分項：待確認、待接單、準備中、待取貨；需及時更新並支援操作。
- 菜單管理：新增、編輯、下架餐點。

### 外送員端
- 首次登入需填寫姓名、身分證、駕照、銀行帳戶，並上傳證件照片。
- 顯示供需熱度地圖，熱度= 訂單/(1+ 外送員)，並正規化顯示。
- 列出可接訂單，排序依據使用者出價、距離、等待時間計算。
- 接單後鎖定，確保只有一位外送員。

### 共通
- 所有 RPC 必須使用資料庫鎖防止經濟條件。
- 即時更新透過 Supabase Realtime；商家需在 2 秒內看到新訂單。
- 平台初期僅營運臺北市。

## 2. 需求編號與驗改標準
- 建議使用 REQ-端-功能-流水號 格式標記需求，例如 REQ-CUST-ORDER-001。
- 建立需求與測試知昨，對應 Unit，Integration，API，E2E 測試，未實作者標記 TODO。

## 3. UI 規範
- 採用 ChatGPT 風格：背景 #F6F8FC、主要文字 #1C2331、accent #3B82F6 等。
- 字體大小分級： text-xs 12px, text-sm 14px, text-base 16px 等；行距 1.5。
- 閒距採用 sp-scale： sp-0=0px, sp-1=4px, sp-2=8px 等。
- 主要組件：按鈕、輸入框、卡片、模態窗、Toast、Skeleton。
- 動效：進出動畫 200-300ms, 列表新增/刪除 80ms，SafeListAnimation 防重複點擊。

## 4. 開發與測試流程
- 分支策略： main 用於 production，develop 用於整合，feature/* 用於開發。
- TDD：先寫測試再寫功能；測試包含單元測試、整合測試、API 測試、E2E 測試。
- 本地環境：使用 supabase start 重建資料庫，執行 seed，通過 melos 管理 packages。
- CI/CD：GitHub Actions 啟動 PostgreSQL、Supabase，執行所有測試並建置 APK。未完成證帳方案時可將 API 測試 continue-on-error 避免 401 失敗。

## 5. 已完成與待完成項目
- 已完成：Monorepo 架構 (3 apps + shared packages)、核心資料模型 (Order, OrderEvent 等)、價格驗證器、外送員排序、部分 UI 組件、基本訂單流程、資料庫遷移與 Supabase 整合。
- 待完成：OTP 認證流程、RLS 測試 stub、完整菜單管理、推播通知、客服中心等。按優先項排列並標記 TODO。

## 6. 安全與限制
- 未完成全資安證流程，目前 API 測試使用假 JWT 會回傳 401，可在 CI 中設置 skip。
- 不要將任何真實密鑰或應用寄入 repo；使用 .env.example 提供範例值。
- RPC 使用 SELECT ... FOR UPDATE 保證接單操作的原子性。

## 7. 種子資料與參考
- infra/supabase/seed 目錄提供初始資料與測試帳號。
- 相關技術文件：Flutter、Supabase、Riverpod、Freezed 等可參閱官方說明。

# TEST_CASES.md — ClearBox Delivery（三端白皮書對應測試案例範本）

> 此文件是 **三端白皮書（顧客端 / 外送員端 / 店家端）** 的測試對照表與可執行測試規格（TDD）。
> 目標：讓 Cursor／CI 能以此檔為「唯一事實來源（SSOT）」自動生成測試、驗收條件與樣板程式碼，並在 PR Gate 上嚴格把關。

---

## 0. 使用方式（給 Cursor / CI 的指令）

* **在每次開始生成程式碼前**，請完整讀取 `/docs/*.md`（白皮書）與本檔 `TEST_CASES.md`：

  * *Prompt 建議：* `Read all specs in /docs and the TEST_CASES.md. Only generate code that satisfies every MUST test.`
* **生成程式碼時**，務必同步產出或更新對應的：

  * 單元測試（Deno / Jest for Deno）
  * API 測試（Postman Collection + Newman）
  * 端到端測試（Playwright）
  * RLS/權限測試（SQL/HTTP）
  * CI 腳本（GitHub Actions）
* **PR 必須通過**：schema migration、RLS、Edge Functions、API、E2E、效能與安全基本檢查，否則不可合併。

---

## 1. 需求追蹤編碼規範（Requirement IDs）

為了將白皮書需求 ↔ 測試用例 ↔ 代碼互相對齊，為每一條「可驗證需求」建立唯一 ID：

* 命名：`REQ-<端別>-<模組>-<流水號>`，例如：

  * `REQ-CUST-ORDER-001`（顧客端-下單流程-001）
  * `REQ-MER-CO-002`（店家端-CurrentOrders-002）
  * `REQ-COU-MATCH-003`（外送員端-媒合-003）
* **白皮書中以方括號標註**：例如「[REQ-MER-CO-002] 店家能在 2 秒內看到即時新訂單加入列表」。
* 本檔中的所有測試用例也以相同 ID 連結，形成 **Traceability Matrix**。

---

## 2. 測試分層與覆蓋範圍

* **Unit**：純函式與小模組（例：H3 計算、排序公式、費率計算）。
* **Integration**：Edge Functions / Supabase RPC / Realtime 通道之間的互動（需要啟動測試資料庫）。
* **API（Contract）**：Postman + Newman 驗證 REST/RPC 合約；狀態碼、Schema、錯誤碼。
* **E2E**：Playwright 驗證關鍵使用流程（可使用 Flutter Web build 或 Web Portal）。
* **Policy（RLS/ACL）**：驗證 Row-Level Security、角色權限、資料隔離。
* **Performance**：P95/P99 延遲、吞吐、資源使用；關鍵函式與 API 的 SLA/SLO。
* **Chaos / Concurrency**（可選）：「雙人同時接單」等競態條件。

---

## 3. 測試資料夾結構（建議）

```
/clearbox-delivery/
├─ /docs/
│   ├─ customer_app_whitepaper.md
│   ├─ courier_app_whitepaper.md
│   ├─ merchant_app_whitepaper.md
│   └─ TEST_CASES.md ← 本檔
├─ /supabase/
│   ├─ migrations/
│   ├─ seed/
│   │   ├─ base_seed.sql
│   │   └─ e2e_fixtures.sql
│   └─ policies/
├─ /functions/ (Deno Edge Functions)
├─ /tests/
│   ├─ unit/ (deno)
│   ├─ integration/ (deno)
│   ├─ api/ (postman_collections)
│   ├─ e2e/ (playwright)
│   └─ rls/ (sql + http)
├─ /.github/workflows/
│   └─ ci.yml
└─ /scripts/
    ├─ run_newman.sh
    └─ seed_test_db.sh
```

---

## 4. 全域前置與測試資料（Fixtures）

* **資料庫**：為 test 環境建立 **獨立** Postgres / Supabase 實例；CI 透過 `supabase db reset` + migrations + seed。
* **固定種子**：`/supabase/seed/base_seed.sql` 建立三端用戶、基本店家、地理座標、菜單、熱門餐點、測試金流帳號等。
* **JWT/Keys**：於 CI 設 `SUPABASE_URL`、`SUPABASE_ANON_KEY`、`SERVICE_ROLE_KEY`，API 測試用。**勿**將真實密鑰 commit。
* **地理資料**：H3 res=10 與 k=40 的測試樣本（台北 2–3 個商圈），確保媒合與等值圈邏輯可重現。

---

## 5. 狀態機與事件流（核心）

**訂單狀態（例）**：
`DRAFT → PENDING_STORE_CONFIRM → WAITING_COURIER → COURIER_ASSIGNED → PICKED_UP → DELIVERING → DELIVERED → CLOSED`

**重要不變式**：

* 顧客自由定價（`delivery_price_user_set`）不可被平台直接改寫；僅可被 **顧客**或**取消/重下單流程**影響。[REQ-CUST-ORDER-001]
* 店家需先確認庫存與打包可行性，才可進入「等待外送員」。[REQ-MER-CO-001]
* 同一訂單 **僅能**被 **單一外送員** 成功接下；競態下需原子性鎖定。[REQ-COU-MATCH-003]
* 任一狀態轉換都必須寫入 `order_events`（可審計）。[REQ-CORE-AUDIT-001]

> **測試規則**：任一流程測試必須同時驗證狀態轉換、事件紀錄、通知（Realtime 或推播）的 **三者一致性**。

---

## 6. Traceability Matrix（節選）

| REQ ID             | 來源白皮書                                     | 測試類型                     | 用例編號                | 摘要                              |
| ------------------ | ----------------------------------------- | ------------------------ | ------------------- | ------------------------------- |
| REQ-CUST-ORDER-001 | customer_app_whitepaper.md §下單流程          | Unit/Integration/API/E2E | TC-CUST-001~006     | 顧客自由定價、最小/最大邊界、非法值拒絕、取消/重下單     |
| REQ-MER-CO-001     | merchant_app_whitepaper.md §CurrentOrders | Integration/E2E          | TC-MER-CO-001~004   | 店家確認庫存→進入等待外送員；2 秒內清單更新         |
| REQ-MER-CO-002     | merchant_app_whitepaper.md §CurrentOrders | E2E                      | TC-MER-E2E-001      | 即時訂單於 2 秒內可見，安全動畫不誤觸             |
| REQ-COU-MATCH-003  | courier_app_whitepaper.md §接單             | Integration/Policy/Chaos | TC-COU-ACPT-001~003 | 兩人同時接單→只有 1 人成功，其餘 409/已被接      |
| REQ-COU-SORT-001   | courier_app_whitepaper.md §接單             | Unit                     | TC-COU-SORT-001     | 訂單依 R/T 優先級排序（收益/時間）            |
| REQ-CORE-AUDIT-001 | 共通                                        | Integration              | TC-AUDIT-001~003    | 每次狀態轉換均落地 `order_events`，事件順序正確 |
| REQ-RLS-ISO-001    | 共通                                        | Policy                   | TC-RLS-001~006      | 顧客/店家/外送員僅能看到與己相關資料             |
| REQ-AUTH-OTP-001   | 三端白皮書 §註冊                                | Integration              | TC-AUTH-001~002     | Email OTP：上限20次/裝置，30秒冷卻       |
| REQ-AUTH-OTP-002   | 三端白皮書 §註冊                                | Integration              | TC-AUTH-003         | Phone OTP：上限5次/裝置，2分鐘冷卻        |
| REQ-GEO-H3-001     | 共通                                        | Unit                     | TC-GEO-H3-001       | H3 res=10 轉換與 k=40 鄰近圈正確計算      |

> **實作時務必擴充此表**，覆蓋所有 REQ。

---

## 7. 典型測試用例（Given/When/Then）

### TC-CUST-001（自由定價：有效邊界） — [REQ-CUST-ORDER-001]

* **Given** 顧客準備建立訂單，輸入 `delivery_price=NT$45`，店家/座標有效
* **When** 呼叫 `POST /rpc/create_order`
* **Then** 回傳 `201`，`order.status=PENDING_STORE_CONFIRM`；DB 中 `delivery_price_user_set=45` 且不可被平台改寫

### TC-CUST-002（自由定價：低於最小值）

* Given 價格 = `NT$0`
* When 呼叫建立訂單
* Then 回傳 `422`，錯誤碼 `ERR_PRICE_MIN`，不得建單

### TC-MER-CO-001（店家確認→等待外送員） — [REQ-MER-CO-001]

* Given 訂單狀態為 `PENDING_STORE_CONFIRM`
* When 店家在 CurrentOrders 按下「確認可製作」
* Then 狀態轉為 `WAITING_COURIER`、寫入 `order_events`、Realtime 推播至外送員清單

### TC-COU-ACPT-001（競態：雙人同時接單） — [REQ-COU-MATCH-003]

* Given 訂單 `WAITING_COURIER`，外送員 A/B 同一時間「接單」
* When 兩請求同時打 `POST /rpc/accept_order`
* Then 僅 1 請求 `200`，另一請求 `409 ERR_ALREADY_ASSIGNED`；DB 僅出現 1 筆 `courier_id`

### TC-AUDIT-001（事件序列） — [REQ-CORE-AUDIT-001]

* Given 完整流程：建單→店家確認→外送員接單→取餐→送達
* Then `order_events` 內有 5+ 筆事件，時間序遞增、關鍵欄位齊全（actor, from_status, to_status, meta）

### TC-RLS-001（資料隔離：顧客） — [REQ-RLS-ISO-001]

* Given 兩名顧客 X/Y
* When 顧客 X 查詢 `/rest/v1/orders?select=*&customer_id=neq.X`
* Then 回傳 0 筆，或 401/403（依 RLS 設定）；**不得**看到他人資料

---

## 8. 單元測試（Deno 範例）

> 檔案：`/tests/unit/h3.spec.ts`

```ts
import { assertEquals, assert } from "https://deno.land/std/testing/asserts.ts";
import { cellDistanceKring, toRes10 } from "../../functions/_lib/h3.ts";

Deno.test("H3: res=10 轉換與 k=40 鄰近圈", () => {
  const store = toRes10([25.0340, 121.5645]);
  const customer = toRes10([25.0360, 121.5630]);
  const ring = cellDistanceKring(store, 40);
  assert(ring.has(customer));
});
```

> 檔案：`/tests/unit/price.spec.ts`

```ts
import { assertEquals } from "https://deno.land/std/testing/asserts.ts";
import { validateUserPrice, scoreOrder } from "../../functions/_lib/pricing.ts";

Deno.test("價格最小值為 30，最大值為 5000（可調）", () => {
  assertEquals(validateUserPrice(0).ok, false);
  assertEquals(validateUserPrice(30).ok, true);
});

Deno.test("排序分數：距離越近、贊助越高分", () => {
  const a = scoreOrder({ meters: 300, sponsor: 1, tip: 0 });
  const b = scoreOrder({ meters: 1200, sponsor: 0, tip: 10 });
  // 預期 a > b（可依白皮書公式微調）
  if (!(a > b)) throw new Error("expected a > b");
});
```

---

## 9. 整合測試（Deno + Supabase Local）

> 檔案：`/tests/integration/order_flow.spec.ts`

```ts
import { assertEquals } from "https://deno.land/std/testing/asserts.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js";

const url = Deno.env.get("SUPABASE_URL");
const anon = Deno.env.get("SUPABASE_ANON_KEY");

Deno.test("顧客建單→店家確認→等待外送員", async () => {
  const supa = createClient(url!, anon!);
  // 顧客建單
  const { data: order, error } = await supa.rpc("create_order", {
    payload: { store_id: "s1", items: [{ sku: "bento", qty: 1 }], delivery_price: 45 }
  });
  if (error) throw error;
  assertEquals(order.status, "PENDING_STORE_CONFIRM");

  // 店家確認
  const { data: ok } = await supa.rpc("merchant_confirm_order", { order_id: order.id });
  assertEquals(ok.status, "WAITING_COURIER");
});
```

---

## 10. API（Contract）測試：Postman + Newman

* Collection：`/tests/api/clearbox.postman_collection.json`
* 環境：`/tests/api/env.test.postman_environment.json`
* **必測**：

  * `POST /rpc/create_order` — 201/422 邊界
  * `POST /rpc/merchant_confirm_order` — 200/409 邏輯
  * `POST /rpc/accept_order` — 200/409 競態
  * `GET /rest/v1/orders?id=eq.{id}` — 200 Schema 驗證
* 變數：`{{SUPABASE_URL}}`、`{{ANON_JWT}}`、`{{MERCHANT_JWT}}`、`{{COURIER_JWT}}`
* **執行**：`./scripts/run_newman.sh`

> `run_newman.sh` 範例

```bash
#!/usr/bin/env bash
newman run ./tests/api/clearbox.postman_collection.json \
  -e ./tests/api/env.test.postman_environment.json \
  --reporters cli,junit --reporter-junit-export ./tests/api/report.xml
```

---

## 11. 端到端（E2E）測試：Playwright

> 以「店家端 Web build」的 CurrentOrders 為例（Flutter Web 或後台 Portal）。

* **關鍵檢查**：

  * 新訂單到達後 **2 秒內** 列表出現（含 loading/過渡動畫不誤觸）。[REQ-MER-CO-002]
  * 點擊卡片可開啟臨時詳情頁；路徑與時間正確渲染。
  * 按「確認可製作」後，狀態變更並有 UI 提示；列表排序/過渡動畫正確。

> `/tests/e2e/merchant-current-orders.spec.ts`

```ts
import { test, expect } from "@playwright/test";

test("CurrentOrders: 新訂單 2 秒內可見", async ({ page }) => {
  await page.goto(process.env.MERCHANT_WEB_URL!);
  await page.getByPlaceholder("Email").fill("merchant@test.com");
  await page.getByRole("button", { name: "登入"}).click();
  const card = page.getByTestId("order-card-#E2E-NEW");
  await expect(card).toBeVisible({ timeout: 2000 });
});
```

> **動畫誤觸防護**：在 E2E 中加入「即時新增/刪除時不錯按」的案例（白皮書要求）。

---

## 12. RLS / 權限測試

* 以 **HTTP 層** 驗證：使用 **不同角色 JWT** 呼叫 PostgREST，確保隔離。
* 典型案例：

  * 顧客不可讀寫他人訂單
  * 外送員僅可讀關聯訂單、不可竄改 `delivery_price_user_set`
  * 店家僅能操作自己店的訂單
* 失敗時應回 `401/403` 或空集合而非隨意 500。

---

## 13. 效能與 SLO（建議初始門檻）

* `POST /rpc/match_orders`：P95 ≤ **150ms**（k=40 搜索、Top-N 排序）
* `accept_order` 原子鎖：在 200 QPS 下 **無重複指派**；錯誤率 ≤ 0.1%
* Realtime 推送（店家確認→外送員清單可見）：P95 ≤ **400ms**
* 所有 Edge Functions 冷啟動 P95 ≤ **700ms**（可透過預熱任務改善）

> CI 中以 **k6/Gatling（可選）** 做 1–3 分鐘 smoke；或以 Deno Bench 驗證關鍵函式。

---

## 14. CI / GitHub Actions（節選）

> `.github/workflows/ci.yml`

```yaml
name: CI
on:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: supabase/postgres:15
        ports: ["5432:5432"]
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd="pg_isready -U postgres" --health-interval=10s --health-timeout=5s --health-retries=5
    steps:
      - uses: actions/checkout@v4
      - uses: denoland/setup-deno@v1
        with: { deno-version: v1.x }
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - name: Supabase CLI
        run: |
          curl -fsSL https://supabase.io/cli/install | sh
          echo "$HOME/.supabase/bin" >> $GITHUB_PATH
      - name: DB reset + migrate + seed
        env:
          SUPABASE_DB_URL: postgresql://postgres:postgres@localhost:5432/postgres
        run: |
          supabase db reset --db-url $SUPABASE_DB_URL
          psql $SUPABASE_DB_URL -f ./supabase/seed/base_seed.sql
      - name: Unit & Integration (Deno)
        run: deno test -A ./tests/unit ./tests/integration
      - name: API (Newman)
        run: |
          npm ci
          ./scripts/run_newman.sh
      - name: E2E (Playwright)
        run: |
          npx playwright install --with-deps
          npx playwright test
```

> **注意**：若使用 Supabase Local（Docker Compose），可在 CI 開 container；或改用遠端測試資料庫。

---

## 15. 驗收門檻（Definition of Done）

* 所有 **MUST** 級別用例 100% 通過；**SHOULD** ≥ 90%。
* 重要路徑（下單→確認→接單→送達）E2E 穩定通過三次。
* RLS 測試全綠；任何資料越權一律視為 **阻擋合併**。
* 效能門檻達標（見 §13）。
* 生成之程式碼與測試 **雙向鏈結**至 REQ IDs（註解 / 測試名稱含 ID）。

---

## 16. 變更流程（當白皮書更新）

1. 在白皮書中新增/修改 REQ（含 ID）。
2. 本檔對應新增/調整測試用例（同 ID）。
3. `ci.yml` 自動跑完所有測試，確保無迴歸。
4. PR 描述中貼上「受影響 REQ 列表」。

---

## 17. 給 Cursor 的生成規則（硬性要求）

* 若某段程式碼無對應 REQ 測試，**不要生成**（或標註 TODO/待定）。
* 任何變更需自動：

  1. 產生/更新單元與整合測試
  2. 更新 Postman Collection Schema
  3. 更新 Playwright 用例（若影響 UX）
* 競態操作（接單）一律用 **資料庫條件更新** 或 **鎖** 來保證唯一性（並寫對應測試）。

---

## 18. 風險與邊界條件（必測）

* **動畫誤觸**：即時新增/刪除時，按鈕不應錯位造成誤點（E2E 驗證）。
* **GPS/定位缺失**：缺座標時應有 UI 與後端防護，禁止建單。
* **資料一致性**：任何狀態變更均以 DB 為準；前端顯示需容忍最終一致。
* **金流不經平台**：若新增線上支付但不走平台金流，所有金額欄位與審計紀錄需明確（不可混淆 `delivery_price_user_set`）。

---

## 19. 補充：對應白皮書章節的最小用例清單（起步包）

### 顧客端（Customer）

* 建單（有效/無效價）
* 取消（等待店家 / 等待外送員 / 已接單）
* 重新下單（沿用舊品項、價可調）
* 查詢歷史訂單（僅限本人）

### 店家端（Merchant）

* CurrentOrders 即時刷新（≤2s）
* 詳情彈層：路徑/時間渲染
* 確認可製作 → 等待外送員
* 歷史訂單查詢（可篩狀態/日期）

### 外送員端（Courier）

* 清單排序（距離/贊助/上週供餐數等公式）
* 接單競態：唯一成功
* 取餐→送達→完單
* 周邊供需熱度層（H3 轉換正確）

---

> **備註**：本檔僅為起始範本。請依三端白皮書逐條補齊 REQ 與測試用例，
> 並確保 CI 在每次 PR 自動跑完所有檢查。

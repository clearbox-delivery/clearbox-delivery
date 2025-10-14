# ClearBox MVP Implementation Plan (ordered)

Purpose: Implement all gaps between the current repo and the four whitepapers (`customer_app_whitepaper.md`, `merchant_app_whitepaper.md`, `courier_app_whitepaper.md`, `UI_GUIDELINES.md`). Each task lists: scope, target files, and acceptance criteria. Do NOT execute changes here; this is the source plan for implementation.

Legend
- Files are relative to repo root. Create files if missing.
- AC = Acceptance Criteria (verifiable checks). Tests to be added later in existing test suites where applicable.

---

## Phase 0 – Foundations and contracts

0.1 Unify design tokens and component usage
- Files:
  - `packages/core_ui/lib/src/theme/design_tokens.dart`
  - `packages/core_ui/lib/src/theme/app_theme.dart`
  - `packages/core_ui/lib/src/widgets/*` (ensure Button/Input/Card/Modal/Tabs/Toast/Skeleton)
- Actions:
  - Ensure token set matches UI_GUIDELINES.md (colors, spacing, typography, motion, focus ring).
  - Add standard `CBModal`, `CBTabs`, `CBToast`, `CBSkeleton` if missing; expose in `core_ui.dart`.
- AC:
  - No inline hardcoded colors/spacing in app pages.
  - Focus ring, hover/active, and motion timing follow tokens.
  - Global font stack includes Noto Sans TC.

0.2 Routing and bottom navigation skeletons
- Files:
  - Customer: `apps/customer_app/lib/router/app_router.dart`, `.../widgets/app_nav.dart` (new)
  - Merchant: `apps/merchant_app/lib/router/app_router.dart`, `.../widgets/app_nav.dart` (new)
  - Courier: `apps/courier_app/lib/router/app_router.dart`, `.../widgets/app_nav.dart` (new)
- Actions:
  - Introduce bottom tabs according to whitepapers.
  - Keep login guard + deep link safety.
- AC:
  - Customer tabs: NewOrder, OrderHistory, Account.
  - Merchant tabs: CurrentOrders, OrderHistory, MenuManagement, Account.
  - Courier tabs: CurrentOrders/AvailableOrders, OrderHistory, Account.

0.3 Realtime/push notifications contract
- Files:
  - Docs: `docs/API_NOTIFICATIONS.md` (new)
  - Client: `packages/supabase_client/lib/src/notifications_service.dart` (new)
- Actions:
  - Define topics/payloads for: new order, courier accepted, prep ready, picked up, delivered, arriving in 2m, cancelled.
  - Stub client capable of listening (Supabase Realtime or FCM), with API no-ops for web dev.
- AC:
  - Contract doc exists and referenced by apps.
  - Apps show toast on simulated notification in dev.

0.4 GPS + H3 unification
- Files:
  - `packages/geo_h3/lib/src/h3_service_web.dart`, `.../h3_service_io.dart`
  - `packages/geo_h3/lib/src/gps_service.dart` (new)
- Actions:
  - Provide single API: current position → H3 res=10, k‑ring ops.
  - Web dev fallback documented; IO uses real H3.
- AC:
  - Customer/Courier can obtain current H3 (mock allowed in web dev), APIs shared.

---

## Phase 1 – Auth, Registration, Device Policies

1.1 OTP registration UI (email/phone) with cooldowns and quotas
- Files:
  - Customer: `apps/customer_app/lib/features/auth/presentation/register_flow/` (new screens: email_otp.dart, phone_otp.dart, set_password.dart)
  - Merchant: `apps/merchant_app/lib/features/auth/.../register_flow/` (same set)
  - Courier: `apps/courier_app/lib/features/auth/.../register_flow/` (same set)
  - Shared client: `packages/supabase_client/lib/src/otp_service.dart` (ensure send/verify + deviceId params; wrap existing RPCs)
- Actions:
  - Implement timers: Email 30s resend, device cap 20; Phone 120s resend, device cap 5.
  - Display policy copy in UI.
- AC:
  - Buttons disabled during cooldown; counter visible.
  - Attempts beyond quota show proper error.

1.2 Device binding & simulator policy (prod) + dev bypass
- Files:
  - Docs: `docs/DEVICE_SECURITY.md` (new)
  - Client: `packages/supabase_client/lib/src/device_service.dart` (new)
  - Apps: integrate on first successful verify → bind device; check on login.
- Actions:
  - Bind deviceId at first login; block mismatched devices (prod flag only).
  - Document Play Integrity/App Attest and CAPTCHA; implement dev-mode toggle.
- AC:
  - Env flag controls enforcement; local web runs bypass with banner warning.

---

## Phase 2 – Customer App

2.1 Login screen motion and visuals
- Files: `apps/customer_app/lib/features/auth/presentation/login_page.dart`
- Actions: Logo center→slide up; inputs fade-in; follow motion tokens.
- AC: Animation on first mount; respects reduced motion.

2.2 First-login initial data (mandatory) + address gate every entry
- Files: `apps/customer_app/lib/features/profile/initial_data_page.dart` (new), `.../address/select_address_gate.dart` (new), CRUD pages
- Actions: nickname input; common addresses CRUD; gate before app content each time.
- AC: Cannot proceed without selecting/creating address; persists.

2.3 “今天想吃什麼？” category overlay with bounce
- Files: `apps/customer_app/lib/features/discovery/categories_overlay.dart` (new), `.../store_recommendations_page.dart` (new)
- Actions: overlay bounce; categories grid 2‑per‑row; sorted by ad spend; recommendation cards format text.
- AC: Opens from NewOrder top bar; smooth animations; closes back to tabs.

2.4 Merchant visibility ring and sorting S
- Files: `packages/domain/lib/src/pricing/merchant_sorting.dart` (ensure P95 + min‑max), `apps/customer_app/lib/features/merchants/...`
- Actions: restrict list to H3 res=10 k=40 from selected address; compute S=0.5D+0.5R; integrate weekly meal counts source.
- AC: List items confined to ring and ordered by S; unit tests updated.

2.5 OrderHistory
- Files: `apps/customer_app/lib/features/orders/presentation/order_history_page.dart` (extend), `.../order_details_sheet.dart` (new)
- Actions: card fields per spec; expandable details with actions “評價店家”/“再買一次”.
- AC: Matches whitepaper fields; actions navigate.

2.6 Account page
- Files: `apps/customer_app/lib/features/account/` (new: account_page.dart, notifications.dart, addresses.dart, settings.dart, help_center.dart)
- AC: Sections/entries exist and functional placeholders (dev).

---

## Phase 3 – Merchant App

3.1 Login animation
- Files: `apps/merchant_app/lib/features/auth/presentation/login_page.dart`
- AC: Same as customer.

3.2 First-login initial data (store profile & verifications) (mandatory)
- Files: `apps/merchant_app/lib/features/profile/initial_store_setup/` (new; steps A–E forms), image capture/upload stubs
- Actions: store profile; business registration; food registration; menu ingestion upload; bankbook photo + account.
- AC: Cannot access app until completed (dev bypass documented).

3.3 CurrentOrders tabs – full card data + flows
- Files: `apps/merchant_app/lib/features/orders/presentation/current_orders_page.dart` (extend), `.../order_detail_sheet.dart` (extract), `packages/supabase_client/lib/src/order_service.dart` (ensure RPCs), `packages/core_ui/lib/src/widgets/order_card.dart` (fields)
- Actions: implement:
  - Pending Confirm: countdown, capacity warning from volume×qty, confirm flow A–D, cancel with reasons, timeline event.
  - Waiting Courier: match progress metrics, adjust prep time ±5, cancel, details with route/capacity.
  - Preparing: courier info/ETA, delay +5/+10, contact courier, exceptional cancel rules.
  - Picked-up: route, ETA, issue report, status to history.
  - Stable list animation to avoid mis-taps.
- AC: Each tab shows correct fields/actions; timeline events created; realtime updates visible ≤2s.

3.4 MenuManagement – categories, batch ops, inventory, options
- Files: `apps/merchant_app/lib/features/menu/...` (extend), `packages/supabase_client/lib/src/menu_service.dart` (add fields), migrations as needed (doc only)
- AC: Category reorder/hide; batch up/down shelf; inventory counters; options/add-ons; prep time; volume/weight; preview; confirm dialogs.

3.5 Merchant OrderHistory & Account
- Files: `apps/merchant_app/lib/features/history/` (new), `apps/merchant_app/lib/features/account/` (new)
- AC: History filters + CSV export; Account sections and toggles as spec.

---

## Phase 4 – Courier App

4.1 Login animation and first-login KYC flow
- Files: `apps/courier_app/lib/features/auth/...` (login motion); `apps/courier_app/lib/features/kyc/` (new stepper screens); storage upload client.
- AC: Sequential capture steps with dev bypass option.

4.2 Heat map spec implementation
- Files: `apps/courier_app/lib/features/heat/presentation/heat_map_widget.dart` (extend), `packages/supabase_client/lib/src/location_service.dart` (ensure RPC), `packages/domain/lib/src/heat/heat_math.dart` (new)
- Actions: compute S, P10/P90 normalization, gamma curve, EMA smoothing; color palette; GPS‑based center cell.
- AC: Visual heat aligns with formula; unit tests for math.

4.3 “我要接單” progress flow (4 stages)
- Files: `apps/courier_app/lib/features/orders/flow/` (new: stage1_find.dart, stage2_go_merchant.dart, stage3_wait_merchant.dart, stage4_go_customer.dart, settle.dart)
- Actions: Stage 1 list sorted by R/T; Stages 2–4 UIs and transitions; photo capture & codes where required; “arriving in 2m” push.
- AC: Can complete end‑to‑end mock flow; correct transitions and toasts.

4.4 Courier OrderHistory & Account
- Files: `apps/courier_app/lib/features/history/` (new), `apps/courier_app/lib/features/account/` (new)
- AC: Today/Week/All tabs with metrics; account sections per spec.

---

## Phase 5 – Tests, docs, and CI alignment

5.1 Unit/Integration/E2E updates
- Files: under `tests/` and package tests
- Actions: add tests for OTP timers, sorting S and R/T, heat math, realtime stability; update CI to run.
- AC: All tests pass locally; CI green.

5.2 Documentation updates
- Files: `docs/customer_app_whitepaper.md`, `docs/merchant_app_whitepaper.md`, `docs/courier_app_whitepaper.md`, `docs/UI_GUIDELINES.md`
- Actions: add missing implementation details discovered (dev bypass, notification payloads, CSV fields, proof‑of‑delivery media requirements).
- AC: Docs and app align; ADR link if any deviation.

---

## Phase 6 – Acceptance checklist
- Each screen matches whitepaper screenshots/fields.
- Realtime latency ≤ 2s for merchant lists.
- GPS/H3 ring filtering works; OSRM or documented dev fallback.
- OTP quotas and cooldowns enforced (dev flaggable).
- Navigation tabs and routes present across apps.
- A11y, focus rings, motion tokens verified.



# Completed / Superseded Implementation Plans and TODOs

Purpose: Prevent confusion by consolidating previously claimed 100% completion summaries and scattered TODO placeholders. This document marks them as superseded by `docs/implementation_plan.md`.

## Superseded high‑level reports (status claims)
- `FINAL_MVP_REPORT.md` – superseded
- `MVP_COMPLETION_REPORT.md` – superseded
- `MVP_FINAL_SUMMARY.md` – superseded
- `PROJECT_COMPLETE.md` – superseded
- `READY_FOR_PR.md` – superseded
- `HANDOVER.md` – superseded
- `docs/IMPLEMENTATION_STATUS.md` – superseded
- `PR_SUMMARY.md` – superseded
- `IMPLEMENTATION_SUMMARY.md` – superseded
- `NEXT_STEPS.md` – superseded

Notes: These files asserted 100% completion. They are retained for historical context only and must not be used for planning. Current source of truth: `docs/implementation_plan.md` and the four whitepapers.

## TODO placeholders to revisit under new plan
- Tests (track under Phase 5 of implementation_plan):
  - `tests/e2e/full_order_flow_test.dart` – contains TODO markers
  - `tests/e2e/merchant_current_orders_test.dart` – contains TODO markers
  - `tests/integration/rls_complete_test.dart` – contains TODO markers
  - `tests/integration/rls_test.dart` – contains TODO markers
  - `tests/integration/menu_crud_test.dart` – contains TODO markers
  - `tests/integration/otp_verification_test.dart` – contains TODO markers
- Backend RPC comment stubs:
  - `infra/supabase/migrations/20240102000001_auth_and_menu_rpcs.sql` – `-- TODO: 实际发送 OTP`

## Inline TODOs in app code (to be implemented per plan)
- `apps/courier_app/lib/features/orders/presentation/available_orders_page.dart`
  - Replace GPS placeholder for currentH3Cell; compute travel times.
- `apps/customer_app/lib/features/orders/presentation/new_order_page.dart`
  - Replace hardcoded merchantId with selection from merchant flow.
- `apps/customer_app/lib/features/orders/presentation/order_history_page.dart`
  - Implement order detail sheet.
- `apps/customer_app/lib/features/auth/presentation/login_page.dart`
  - Hook registration flow navigation.

## Next steps
All remaining work must follow `docs/implementation_plan.md`. This file will be updated if more legacy plans or TODO clusters are discovered.

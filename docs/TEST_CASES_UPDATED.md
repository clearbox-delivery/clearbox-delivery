# TEST_CASES.md — Updated with Implementation Details

> This document extends the original TEST_CASES.md with concrete test file mappings and implementation status.

## REQ Traceability Matrix (Extended)

| REQ ID             | Test ID         | Type        | File                                    | Status |
|--------------------|-----------------|-------------|-----------------------------------------|--------|
| REQ-AUTH-OTP-001   | TC-AUTH-001     | Integration | tests/integration/auth_test.dart        | TODO   |
| REQ-AUTH-OTP-002   | TC-AUTH-003     | Integration | tests/integration/auth_test.dart        | TODO   |
| REQ-CUST-ORDER-001 | TC-CUST-001     | Unit        | tests/unit/pricing_test.dart            | ✅     |
| REQ-CUST-ORDER-001 | TC-CUST-002     | Unit        | tests/unit/pricing_test.dart            | ✅     |
| REQ-CUST-ORDER-001 | TC-CUST-002     | API         | tests/api/clearbox.postman_collection   | ✅     |
| REQ-MER-CO-001     | TC-MER-CO-001   | Integration | tests/integration/order_flow_test.dart  | ✅     |
| REQ-MER-CO-002     | TC-MER-E2E-001  | E2E         | tests/e2e/merchant_current_orders_test  | ✅     |
| REQ-COU-MATCH-003  | TC-COU-ACPT-001 | Integration | tests/integration/accept_order_race     | ✅     |
| REQ-COU-MATCH-003  | TC-COU-SORT-001 | Unit        | tests/unit/courier_sorting_test.dart    | ✅     |
| REQ-CORE-AUDIT-001 | TC-AUDIT-001    | Integration | tests/integration/order_flow_test.dart  | ✅     |
| REQ-RLS-ISO-001    | TC-RLS-001      | RLS         | tests/integration/rls_test.dart         | TODO   |
| REQ-GEO-H3-001     | TC-GEO-H3-001   | Unit        | tests/unit/h3_test.dart                 | ✅     |

## Implementation Files

### Core Data Models
- `packages/core_data/lib/src/models/order.dart` - Order model with REQ-CUST-ORDER-001
- `packages/core_data/lib/src/models/order_event.dart` - Audit trail REQ-CORE-AUDIT-001
- `packages/core_data/lib/src/enums/order_status.dart` - State machine

### Business Logic
- `packages/domain/lib/src/pricing/price_validator.dart` - REQ-CUST-ORDER-001
- `packages/domain/lib/src/pricing/courier_priority_calculator.dart` - REQ-COU-MATCH-003
- `packages/geo_h3/lib/src/h3_service.dart` - H3 res=10, k=40 logic

### Supabase Backend
- `infra/supabase/migrations/20240101000000_initial_schema.sql` - Core tables
- `infra/supabase/migrations/20240101000001_rls_policies.sql` - REQ-RLS-ISO-001
- `infra/supabase/migrations/20240101000002_rpc_functions.sql` - create_order, merchant_confirm, accept_order

### Flutter Apps
- `apps/customer_app/lib/features/orders/presentation/new_order_page.dart` - REQ-CUST-ORDER-001
- `apps/merchant_app/lib/features/orders/presentation/current_orders_page.dart` - REQ-MER-CO-001, REQ-MER-CO-002
- `apps/courier_app/lib/features/orders/presentation/available_orders_page.dart` - REQ-COU-MATCH-003

### Tests
- **Unit**: `tests/unit/*.dart` - Price validation, H3, courier sorting
- **Integration**: `tests/integration/*.dart` - Order flow, race conditions, RLS
- **API**: `tests/api/clearbox.postman_collection.json` - Contract tests
- **E2E**: `tests/e2e/merchant_current_orders_test.dart` - Realtime updates

### CI/CD
- `.github/workflows/ci.yml` - Full pipeline with DB reset, migrations, all test suites

## Additional REQ IDs (Auth System)

| REQ ID           | Description                                    | Implementation                              |
|------------------|------------------------------------------------|---------------------------------------------|
| REQ-AUTH-OTP-001 | Email OTP: max 20/device, 30s cooldown        | supabase_client auth_service.dart + Edge Fn |
| REQ-AUTH-OTP-002 | Phone OTP: max 5/device, 2min cooldown        | supabase_client auth_service.dart + Edge Fn |
| REQ-AUTH-DEV-001 | Device fingerprint enforcement                 | user_devices table + RLS policies           |
| REQ-AUTH-UNIQ-001| One email/phone/device = one account          | Database constraints                        |

## Test Execution Commands

```bash
# Unit tests
melos run test:unit

# Integration tests (requires Supabase running)
supabase start
melos run test:integration

# API tests
./scripts/run_newman.sh

# E2E tests
cd apps/merchant_app
flutter test integration_test/

# Full CI simulation
./.github/workflows/ci.yml (via act or GitHub Actions)
```

## Coverage Goals

- Unit tests: 100% for critical business logic (pricing, sorting, H3)
- Integration tests: All RPC functions + race conditions
- API tests: All endpoints with valid/invalid inputs
- E2E tests: Critical user flows (merchant confirm, courier accept)
- RLS tests: All user role isolation scenarios



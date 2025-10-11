<!-- 231eda9f-aa8b-464d-8ffb-0c08f1cc1276 b90a837b-c499-4590-8d60-bfba148d987e -->
# Flutter MVP Scaffold Plan

## 1. Monorepo Structure

Create Flutter monorepo with shared packages architecture:

```
clearbox-delivery/
├── apps/
│   ├── customer_app/          # 顾客端
│   ├── courier_app/           # 外送员端
│   └── merchant_app/          # 店家端
├── packages/
│   ├── core_ui/               # Shared widgets, theme, animations
│   ├── core_data/             # Models, DTOs (freezed/json_serializable)
│   ├── domain/                # Business logic, use cases
│   ├── supabase_client/       # Supabase setup, auth, realtime
│   └── geo_h3/                # H3 geospatial helpers
├── infra/
│   └── supabase/
│       ├── migrations/        # Schema DDL
│       ├── seed/
│       │   ├── 01_base.sql   # Roles, policies, base data
│       │   └── seed_dynamic.ts # Deno script for test fixtures
│       └── functions/         # Edge Functions (auth gateway, RPCs)
├── tests/
│   ├── unit/                  # Dart unit tests
│   ├── integration/           # Dart integration tests (Supabase)
│   ├── api/                   # Postman + Newman
│   └── e2e/                   # Flutter integration_test
└── .github/workflows/
    └── ci.yml
```

**Key packages**:

- `go_router` (routing)
- `riverpod` (state management)
- `freezed` + `json_serializable` (models)
- `supabase_flutter` (client)
- `intl` (i18n/formatting)
- `flutter_lints` (strict)
- `h3_flutter` or custom H3 bindings

## 2. Authentication System (REQ-AUTH-*)

### 2.1 Supabase Auth + Custom OTP Flow

**Tables**:

- `user_devices` (device_id, user_id, first_seen_at, last_seen_at, is_blocked)
- `otp_rate_limits` (identifier, attempt_count, last_attempt_at, lock_until)

**Edge Functions**:

- `auth-gateway` - Rate limit enforcement for OTP sends
        - Email OTP: max 20/device, 30s cooldown [REQ-AUTH-OTP-001]
        - Phone OTP: max 5/device, 2min cooldown [REQ-AUTH-OTP-002]
- `verify-device` - Device fingerprint validation

**Flow**:

1. Email OTP → verify → Phone OTP → verify → Password set → auto-login
2. Device fingerprint captured on first registration, checked on login
3. One email/one phone/one device = one account enforcement

**UI Components** (in `core_ui`):

- `OtpInputField` (6-digit, auto-focus)
- `CooldownButton` (resend with timer)
- `DeviceLimitExceededDialog`

### 2.2 Test Cases (add to TEST_CASES.md)

- `TC-AUTH-001`: Valid email OTP within 20 attempts
- `TC-AUTH-002`: Email OTP lock after 20 attempts
- `TC-AUTH-003`: Phone OTP 2min cooldown enforcement
- `TC-AUTH-004`: Device fingerprint mismatch blocks login
- `TC-AUTH-005`: Same email cannot register twice (409)

## 3. Supabase Schema & Migrations

### 3.1 Core Tables

**orders**:

```sql
- id (uuid, pk)
- customer_id, merchant_id, courier_id (uuid, fk)
- status (enum: PENDING_STORE_CONFIRM, WAITING_COURIER, COURIER_ASSIGNED, PICKED_UP, DELIVERED, CANCELLED_*)
- delivery_price_user_set (numeric, NOT NULL) -- [REQ-CUST-ORDER-001]
- items (jsonb)
- h3_merchant, h3_customer (text) -- res=10
- created_at, updated_at
```

**order_events** (audit trail):

```sql
- id (bigserial, pk)
- order_id (uuid, fk)
- actor_id, actor_type (uuid, text)
- from_status, to_status (text)
- event_type (text)
- metadata (jsonb)
- created_at (timestamptz)
```

**merchants**:

```sql
- id, name, address, google_maps_url
- h3_cell (text, res=10)
- menu (jsonb) -- temporary MVP approach
- prep_time_minutes (int)
```

**couriers**:

```sql
- id, name, current_h3_cell (text)
- is_online (boolean)
```

### 3.2 RLS Policies [REQ-RLS-ISO-001]

- Customers: only see own orders (`customer_id = auth.uid()`)
- Merchants: only orders for their store (`merchant_id = auth.uid()`)
- Couriers: only assigned or available orders (complex policy)

### 3.3 RPC Functions

**create_order** (customer):

- Validate `delivery_price_user_set >= 30, <= 5000`
- Insert order with status `PENDING_STORE_CONFIRM`
- Insert event to `order_events`

**merchant_confirm_order**:

- Check stock, prep time input
- Update status → `WAITING_COURIER`
- Broadcast via Realtime

**accept_order** (courier):

- Atomic CAS: `UPDATE orders SET courier_id = $1 WHERE id = $2 AND courier_id IS NULL`
- Return 409 if already assigned [REQ-COU-MATCH-003]

## 4. Shared Packages Implementation

### 4.1 `core_data` - Models

```dart
// REQ-CUST-ORDER-001
@freezed
class Order with _$Order {
  factory Order({
    required String id,
    required OrderStatus status,
    required double deliveryPriceUserSet, // immutable after creation
    required List<OrderItem> items,
    // ...
  }) = _Order;
  
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}
```

### 4.2 `supabase_client` - Setup

```dart
class SupabaseClientProvider {
  static final instance = Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  
  // Realtime subscriptions
  Stream<List<Order>> watchMerchantOrders(String merchantId) {
    return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('merchant_id', merchantId)
      .order('created_at')
      .map((rows) => rows.map(Order.fromJson).toList());
  }
}
```

### 4.3 `geo_h3` - H3 Helpers

```dart
// REQ unit test: TC-GEO-H3-001
String toH3Res10(LatLng coord) {
  return h3.geoToH3(coord.lat, coord.lng, 10);
}

Set<String> kRing(String cell, int k) {
  return h3.kRing(cell, k);
}

// Unit test: verify k=40 ring calculation
```

### 4.4 `core_ui` - Animations

**SafeListAnimation** (prevents mis-taps during realtime updates):

- Use `AnimatedList` with stable keys
- Delay touch during insert/remove animations (200ms)
- Highlight new items with fade-in pulse
```dart
class SafeOrderList extends StatefulWidget {
  // REQ-MER-CO-002: ≤2s visibility with safe animations
}
```


## 5. App-Level Features by Role

### 5.1 Customer App (REQ-CUST-*)

**Pages**:

- `LoginPage` → `OtpVerificationPage` → `NewOrderPage`
- `NewOrderPage`:
        - Price input with validation [REQ-CUST-ORDER-001]
        - Items selection (simple list for MVP)
        - Submit → call `create_order` RPC
- `OrderHistoryPage`:
        - List past orders with expand details
        - "Rate Merchant" / "Order Again" buttons

**Routes** (go_router):

```dart
GoRoute(path: '/new-order', builder: (context, state) => NewOrderPage()),
GoRoute(path: '/history', builder: (context, state) => OrderHistoryPage()),
```

### 5.2 Merchant App (REQ-MER-*)

**Pages**:

- `CurrentOrdersPage` (4 tabs: 待确认/待接单/备餐中/已取餐)
        - **Realtime stream** with `SafeListAnimation`
        - Tap card → `OrderDetailSheet` (bottom sheet)
        - [REQ-MER-CO-001] Confirm button → call `merchant_confirm_order`
        - [REQ-MER-CO-002] New order visible ≤2s

**Implementation**:

```dart
class CurrentOrdersPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersStream = ref.watch(merchantOrdersStreamProvider);
    
    return ordersStream.when(
      data: (orders) => SafeOrderList(orders: orders),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => ErrorWidget(e),
    );
  }
}
```

### 5.3 Courier App (REQ-COU-*)

**Pages**:

- `AvailableOrdersPage`:
        - Sorted list by R/T (revenue/time) formula
        - Pull to refresh
        - Tap → `AcceptOrderDialog`
- `AcceptOrderDialog`:
        - Show order details
        - Button → call `accept_order` RPC
        - Handle 409 conflict [REQ-COU-MATCH-003]

**Sorting Logic** (unit test: TC-COU-SORT-001):

```dart
double calculatePriority(Order order, LatLng courierLocation) {
  final R = order.deliveryPriceUserSet;
  final T = max(
    estimateTravelTime(courierLocation, order.merchantLocation),
    order.prepTimeMinutes
  ) + order.deliveryTimeMinutes;
  
  return R / max(T, 5.0); // min 5min to avoid noise
}
```

## 6. Test Implementation

### 6.1 Unit Tests (Dart)

**tests/unit/pricing_test.dart**:

```dart
// TC-CUST-001
test('Valid delivery price 30-5000', () {
  expect(validatePrice(45), isTrue);
  expect(validatePrice(0), isFalse); // TC-CUST-002
  expect(validatePrice(6000), isFalse);
});
```

**tests/unit/h3_test.dart**:

```dart
// TC-GEO-H3-001
test('H3 res=10 conversion and k=40 ring', () {
  final cell = toH3Res10(LatLng(25.0340, 121.5645));
  final ring = kRing(cell, 40);
  expect(ring.length, greaterThan(1));
});
```

**tests/unit/courier_sorting_test.dart**:

```dart
// TC-COU-SORT-001
test('Orders sorted by R/T descending', () {
  final orders = [
    Order(deliveryPrice: 50, totalTime: 10), // 5.0
    Order(deliveryPrice: 80, totalTime: 20), // 4.0
  ];
  final sorted = sortOrdersByPriority(orders, courierLoc);
  expect(sorted.first.deliveryPrice, 50);
});
```

### 6.2 Integration Tests (Dart + Supabase)

**tests/integration/order_flow_test.dart**:

```dart
// TC-MER-CO-001
testWidgets('Merchant confirms order → status WAITING_COURIER', (tester) async {
  final supabase = await getTestSupabaseClient();
  
  // Create pending order
  final order = await supabase.rpc('create_order', params: {...});
  expect(order['status'], 'PENDING_STORE_CONFIRM');
  
  // Merchant confirms
  final result = await supabase.rpc('merchant_confirm_order', 
    params: {'order_id': order['id'], 'prep_time': 15});
  expect(result['status'], 'WAITING_COURIER');
  
  // Check event audit
  final events = await supabase.from('order_events')
    .select().eq('order_id', order['id']);
  expect(events.length, greaterThanOrEqualTo(2)); // TC-AUDIT-001
});
```

**tests/integration/accept_order_race_test.dart**:

```dart
// TC-COU-ACPT-001 (race condition)
test('Two couriers accept same order → only one succeeds', () async {
  final courier1 = getSupabaseClient(courier1Jwt);
  final courier2 = getSupabaseClient(courier2Jwt);
  
  final results = await Future.wait([
    courier1.rpc('accept_order', params: {'order_id': orderId}),
    courier2.rpc('accept_order', params: {'order_id': orderId}),
  ]);
  
  final successes = results.where((r) => r.error == null).length;
  expect(successes, 1); // REQ-COU-MATCH-003
});
```

### 6.3 API Contract Tests (Postman + Newman)

**tests/api/clearbox.postman_collection.json**:

- Request: `POST {{SUPABASE_URL}}/rest/v1/rpc/create_order`
- Tests:
  ```js
  pm.test("Valid price returns 201", () => {
    pm.response.to.have.status(201);
    pm.expect(pm.response.json().delivery_price_user_set).to.eql(45);
  });
  
  pm.test("Price below min returns 422", () => {
    // TC-CUST-002
    pm.response.to.have.status(422);
    pm.expect(pm.response.json().code).to.eql("ERR_PRICE_MIN");
  });
  ```


**scripts/run_newman.sh**:

```bash
#!/usr/bin/env bash
newman run tests/api/clearbox.postman_collection.json \
  -e tests/api/env.test.json \
  --reporters cli,junit \
  --reporter-junit-export tests/api/newman-report.xml
```

### 6.4 E2E Tests (Flutter integration_test)

**tests/e2e/merchant_current_orders_test.dart**:

```dart
// TC-MER-CO-002
testWidgets('New order visible within 2s', (tester) async {
  await tester.pumpWidget(MerchantApp());
  
  // Login
  await tester.enterText(find.byKey(Key('email')), 'merchant@test.com');
  await tester.tap(find.text('登入'));
  await tester.pumpAndSettle();
  
  // Trigger new order creation (via test helper)
  await createTestOrder();
  
  // Verify visibility within 2s
  await tester.pump(Duration(milliseconds: 100));
  expect(find.byKey(Key('order-card-new')), findsOneWidget,
    reason: 'REQ-MER-CO-002: Order must appear ≤2s');
});
```

### 6.5 RLS Tests (PostgREST calls)

**tests/integration/rls_test.dart**:

```dart
// TC-RLS-001
test('Customer cannot see other customer orders', () async {
  final customer1 = getSupabaseClient(customer1Jwt);
  
  final result = await customer1
    .from('orders')
    .select()
    .neq('customer_id', customer1Id);
  
  expect(result.data, isEmpty); // REQ-RLS-ISO-001
});
```

## 7. CI/CD Pipeline

**`.github/workflows/ci.yml`**:

```yaml
name: CI Pipeline

on:
  pull_request:
    branches: [develop, main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: supabase/postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports: ['5432:5432']
        options: --health-cmd pg_isready --health-interval 10s
    
    steps:
      - uses: actions/checkout@v4
      
      # Supabase CLI
      - name: Install Supabase CLI
        run: |
          brew install supabase/tap/supabase
      
      # Deno for Edge Functions tests
      - uses: denoland/setup-deno@v1
        with:
          deno-version: v1.x
      
      # Flutter
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          cache: true
      
      # DB Reset + Migrate + Seed
      - name: Setup Database
        env:
          SUPABASE_DB_URL: postgresql://postgres:postgres@localhost:5432/postgres
        run: |
          cd infra
          supabase db reset --db-url $SUPABASE_DB_URL
          psql $SUPABASE_DB_URL < supabase/seed/01_base.sql
          deno run -A supabase/seed/seed_dynamic.ts
      
      # Dart Unit Tests
      - name: Run Dart Unit Tests
        run: |
          cd packages/geo_h3
          flutter test
          cd ../domain
          flutter test
      
      # Dart Integration Tests (Supabase)
      - name: Run Integration Tests
        env:
          SUPABASE_URL: http://localhost:54321
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_TEST_ANON_KEY }}
        run: |
          flutter test tests/integration
      
      # API Tests (Newman)
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      
      - name: Run API Tests
        run: |
          npm install -g newman
          ./scripts/run_newman.sh
      
      # E2E Tests (Flutter web build)
      - name: Run E2E Tests
        run: |
          flutter config --enable-web
          cd apps/merchant_app
          flutter drive \
            --driver=test_driver/integration_test.dart \
            --target=integration_test/current_orders_test.dart \
            -d web-server
      
      # Upload Test Reports
      - uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-reports
          path: |
            tests/api/newman-report.xml
            coverage/
```

## 8. Seeding Strategy

### 8.1 SQL Base Seed (01_base.sql)

```sql
-- Roles
INSERT INTO auth.users (id, email) VALUES
  ('cust-1', 'customer@test.com'),
  ('mer-1', 'merchant@test.com'),
  ('cou-1', 'courier@test.com');

-- Merchants
INSERT INTO merchants (id, name, address, h3_cell, menu) VALUES
  ('mer-1', '测试便当店', '台北市XX路', '8a1234567890abc', '[...]');

-- Sample menu items in JSONB
```

### 8.2 Dynamic Script Seed (seed_dynamic.ts)

```typescript
// Generate variable test data
import { createClient } from 'https://esm.sh/@supabase/supabase-js';

const supabase = createClient(Deno.env.get('SUPABASE_URL')!, 
  Deno.env.get('SERVICE_ROLE_KEY')!);

// Create 10 pending orders for TC-MER-CO-001
for (let i = 0; i < 10; i++) {
  await supabase.rpc('create_order', {
    customer_id: 'cust-1',
    merchant_id: 'mer-1',
    delivery_price: 45 + i * 5,
    items: [{ sku: 'bento', qty: 1 }],
  });
}
```

## 9. REQ Traceability Matrix Updates

Add to `TEST_CASES.md`:

```markdown
| REQ ID             | Test ID         | Type        | File                              |
|--------------------|-----------------|-------------|-----------------------------------|
| REQ-AUTH-OTP-001   | TC-AUTH-001     | Integration | tests/integration/auth_test.dart  |
| REQ-CUST-ORDER-001 | TC-CUST-001~002 | Unit/API    | tests/unit/pricing_test.dart      |
| REQ-MER-CO-001     | TC-MER-CO-001   | Integration | tests/integration/order_flow_test |
| REQ-MER-CO-002     | TC-MER-E2E-001  | E2E         | tests/e2e/merchant_co_test.dart   |
| REQ-COU-MATCH-003  | TC-COU-ACPT-001 | Integration | tests/integration/race_test.dart  |
| REQ-CORE-AUDIT-001 | TC-AUDIT-001    | Integration | tests/integration/order_flow_test |
| REQ-RLS-ISO-001    | TC-RLS-001~006  | RLS         | tests/integration/rls_test.dart   |
```

## 10. Implementation Order (Todos)

Dependencies ensure proper scaffolding sequence.

### To-dos

- [ ] Create Flutter monorepo structure with apps/ and packages/ directories, melos.yaml config, and base pubspec files
- [ ] Create Supabase migrations for core tables (orders, order_events, merchants, couriers, user_devices, otp_rate_limits) with RLS policies
- [ ] Build core_data package with freezed models (Order, OrderEvent, Merchant, Courier) and JSON serialization
- [ ] Create supabase_client package with initialization, auth flows, realtime streams, and RPC wrappers
- [ ] Build full auth flow: Edge Functions for OTP rate limiting, device fingerprinting, email/phone verification pages with cooldown buttons
- [ ] Create geo_h3 package with H3 res=10 conversion, k-ring calculations, and distance helpers
- [ ] Build core_ui package with SafeListAnimation widget, theme, OTP input fields, and reusable components
- [ ] Create customer app with NewOrderPage (price validation), OrderHistoryPage, go_router setup, and Riverpod providers
- [ ] Create merchant app with CurrentOrdersPage (4 tabs, realtime streams, SafeListAnimation), OrderDetailSheet, confirm order flow
- [ ] Create courier app with AvailableOrdersPage (R/T sorting), AcceptOrderDialog with conflict handling (409)
- [ ] Create Edge Functions for create_order, merchant_confirm_order, accept_order with atomic operations and audit trail
- [ ] Create 01_base.sql with test users, roles, merchants, sample menus, and base policies
- [ ] Create seed_dynamic.ts Deno script to generate variable test orders and event data
- [ ] Write Dart unit tests for pricing validation, H3 calculations, courier sorting (TC-CUST-001/002, TC-GEO-H3-001, TC-COU-SORT-001)
- [ ] Write Dart integration tests for order flow, race conditions, audit trail (TC-MER-CO-001, TC-COU-ACPT-001, TC-AUDIT-001)
- [ ] Write RLS isolation tests using different JWT tokens for customer/merchant/courier (TC-RLS-001~006)
- [ ] Create Postman collection with API contract tests for all RPCs, Newman runner script (run_newman.sh)
- [ ] Write Flutter integration_test for merchant CurrentOrders realtime updates and 2s visibility requirement (TC-MER-E2E-001)
- [ ] Create .github/workflows/ci.yml with Flutter toolchain, DB reset/seed, all test suites (unit/integration/API/E2E/RLS)
- [ ] Update TEST_CASES.md with REQ-AUTH-* requirements and complete traceability matrix linking all test files
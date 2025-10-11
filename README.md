# ClearBox Delivery - Flutter MVP

Production-grade Flutter monorepo for a food delivery platform with customer, merchant, and courier apps.

## Architecture

### Monorepo Structure

```
clearbox-delivery/
├── apps/                   # Flutter applications
│   ├── customer_app/      # Customer app
│   ├── merchant_app/      # Merchant app
│   └── courier_app/       # Courier app
├── packages/              # Shared packages
│   ├── core_data/        # Data models (freezed)
│   ├── core_ui/          # Shared UI components
│   ├── domain/           # Business logic
│   ├── supabase_client/  # Supabase integration
│   └── geo_h3/           # H3 geospatial utilities
├── infra/                 # Infrastructure
│   └── supabase/
│       ├── migrations/   # Database schema
│       ├── seed/         # Test data
│       └── functions/    # Edge Functions
└── tests/                # Test suites
    ├── unit/            # Dart unit tests
    ├── integration/     # Integration tests
    ├── api/             # Postman/Newman tests
    └── e2e/             # E2E tests
```

### Tech Stack

- **Frontend**: Flutter 3.24+ with Dart 3.0+
- **State Management**: Riverpod
- **Routing**: go_router
- **Backend**: Supabase (PostgreSQL + Edge Functions)
- **Geospatial**: H3 (resolution 10, k=40 radius)
- **Code Generation**: freezed, json_serializable, build_runner
- **Testing**: Dart test, integration_test, Newman, Postman

## Key Features

### Order Lifecycle

1. **Customer creates order** with custom delivery price (NT$30-5000) [REQ-CUST-ORDER-001]
2. **Merchant confirms** manufacturability → status: WAITING_COURIER [REQ-MER-CO-001]
3. **Courier accepts** order (atomic, race-condition safe) [REQ-COU-MATCH-003]
4. **Audit trail** tracks all state transitions [REQ-CORE-AUDIT-001]

### Real-time Updates

- Merchant sees new orders within ≤2s [REQ-MER-CO-002]
- Safe animations prevent mis-taps during list updates
- Supabase Realtime for live order status

### Security

- Row-level security (RLS) isolates data by role [REQ-RLS-ISO-001]
- Full OTP auth flow with device fingerprinting [REQ-AUTH-OTP-001, REQ-AUTH-OTP-002]
- Rate limiting on verification attempts

## Getting Started

### Prerequisites

- Flutter SDK 3.24+
- Dart SDK 3.0+
- Supabase CLI
- Deno (for Edge Functions & seed scripts)
- Node.js 20+ (for Newman)
- Melos (for monorepo management)

### Installation

1. **Clone repository**

```bash
git clone https://github.com/yourorg/clearbox-delivery.git
cd clearbox-delivery
```

2. **Install Melos**

```bash
dart pub global activate melos
```

3. **Bootstrap packages**

```bash
melos bootstrap
```

4. **Generate code (freezed, json_serializable)**

```bash
melos run build:runner
```

### Local Development

1. **Start Supabase**

```bash
cd infra
supabase start
```

2. **Run migrations and seed**

```bash
supabase db reset
psql $SUPABASE_DB_URL < supabase/seed/01_base.sql
deno run -A supabase/seed/seed_dynamic.ts
```

3. **Run app**

```bash
# Customer app
cd apps/customer_app
flutter run --dart-define=SUPABASE_URL=http://localhost:54321 \
            --dart-define=SUPABASE_ANON_KEY=your-anon-key

# Merchant app
cd apps/merchant_app
flutter run --dart-define=SUPABASE_URL=http://localhost:54321 \
            --dart-define=SUPABASE_ANON_KEY=your-anon-key

# Courier app
cd apps/courier_app
flutter run --dart-define=SUPABASE_URL=http://localhost:54321 \
            --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Testing

### Unit Tests

```bash
melos run test:unit
# Or specific package
cd packages/domain
flutter test
```

### Integration Tests

```bash
# Requires Supabase running
supabase start
melos run test:integration
```

### API Tests (Newman)

```bash
npm install -g newman
./scripts/run_newman.sh
```

### E2E Tests

```bash
cd apps/merchant_app
flutter test integration_test/
```

### All Tests (CI simulation)

```bash
melos run test
```

## Test Credentials

For local development:

- **Customer**: `customer@test.com` / `testpass123`
- **Merchant**: `merchant@test.com` / `testpass123`
- **Courier**: `courier@test.com` / `testpass123`

## CI/CD

GitHub Actions pipeline (`.github/workflows/ci.yml`):

1. Setup PostgreSQL + Supabase
2. Run migrations + seed
3. Run all test suites (unit, integration, API, E2E)
4. Build APKs for all apps
5. Upload artifacts & test reports

## Requirements Traceability

See `docs/TEST_CASES_UPDATED.md` for complete mapping:

- REQ → Test Cases → Implementation Files
- Coverage matrix
- Test execution commands

## Key REQ IDs

- `REQ-CUST-ORDER-001`: Customer delivery price (30-5000, immutable)
- `REQ-MER-CO-001`: Merchant confirm → WAITING_COURIER
- `REQ-MER-CO-002`: Real-time updates ≤2s
- `REQ-COU-MATCH-003`: Atomic courier accept (race-safe)
- `REQ-CORE-AUDIT-001`: Order events audit trail
- `REQ-RLS-ISO-001`: Row-level security isolation

## Contributing

1. Create feature branch from `develop`
2. Write tests first (TDD)
3. Implement feature with REQ ID comments
4. Run `melos run analyze` and `melos run test`
5. Open PR to `develop`
6. Ensure CI passes

## Documentation

- [Customer App Whitepaper](docs/customer_app_whitepaper.md)
- [Merchant App Whitepaper](docs/merchant_app_whitepaper.md)
- [Courier App Whitepaper](docs/courier_app_whitepaper.md)
- [Development Flow](docs/DEVELOPMENT_FLOW.md)
- [Test Cases](docs/TEST_CASES.md)
- [Implementation Details](docs/TEST_CASES_UPDATED.md)

## License

Proprietary - All Rights Reserved

# Next Steps - After Scaffold

## 🚀 Immediate Actions (Required to Run)

### 1. Install Dependencies
```bash
# Install Melos globally
dart pub global activate melos

# Bootstrap all packages
melos bootstrap
```

### 2. Generate Code (Freezed/JSON)
```bash
# Generate all freezed and json_serializable files
melos run build:runner

# This will create:
# - *.freezed.dart files for all @freezed models
# - *.g.dart files for all JSON serialization
```

### 3. Setup Supabase Local
```bash
# Install Supabase CLI (if not installed)
# macOS/Linux:
curl -fsSL https://supabase.io/install.sh | sh

# Windows (with scoop):
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Start Supabase
cd infra
supabase start

# Apply migrations
supabase db reset

# Run seed
psql postgresql://postgres:postgres@localhost:5432/postgres < supabase/seed/01_base.sql

# Run dynamic seed
deno run -A supabase/seed/seed_dynamic.ts
```

### 4. Configure Environment Variables

Create `.env` files for each app:

**apps/customer_app/.env:**
```
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key-from-supabase-start
```

**apps/merchant_app/.env:**
```
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key-from-supabase-start
```

**apps/courier_app/.env:**
```
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key-from-supabase-start
```

### 5. Run Apps
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

## 🧪 Run Tests

### Unit Tests
```bash
# All unit tests
cd tests/unit
dart test

# Or specific package tests
cd packages/domain
flutter test
```

### Integration Tests
```bash
# Ensure Supabase is running first
cd tests/integration
dart test
```

### API Tests (Newman)
```bash
# Install Newman
npm install -g newman

# Run API tests
chmod +x scripts/run_newman.sh  # Unix/Mac only
./scripts/run_newman.sh

# Or directly:
newman run tests/api/clearbox.postman_collection.json \
  -e tests/api/env.test.json
```

### E2E Tests
```bash
cd apps/merchant_app
flutter test integration_test/
```

## 🔧 Development Workflow

### Adding New Features

1. **Create feature branch**
```bash
git checkout -b feature/new-feature develop
```

2. **Add REQ ID to feature**
- Document in whitepapers with `[REQ-XXX-YYY-###]`
- Add to TEST_CASES.md traceability matrix

3. **Write tests first (TDD)**
- Unit test in `tests/unit/`
- Integration test in `tests/integration/`
- Update Postman collection if API changes

4. **Implement feature**
- Add REQ ID in code comments
- Use appropriate package (domain for logic, core_ui for widgets)

5. **Generate code if models changed**
```bash
melos run build:runner
```

6. **Run linter**
```bash
melos run analyze
```

7. **Run tests**
```bash
melos run test
```

8. **Commit and push**
```bash
git add .
git commit -m "feat: Description [REQ-XXX-YYY-###]"
git push -u origin feature/new-feature
```

9. **Create PR to develop**

## 📝 TODO: Missing Implementations

### High Priority

1. **Complete Auth Edge Functions**
   - [ ] `/functions/auth-gateway/` - OTP rate limiting
   - [ ] `/functions/verify-device/` - Device fingerprinting
   - [ ] Implement in `infra/supabase/functions/`

2. **Add Missing Package Dependencies**
   - [ ] Add `intl` to core_ui for date formatting
   - [ ] Verify all package versions are compatible

3. **Implement Full RLS Tests**
   - [ ] Create separate auth clients for each role
   - [ ] Complete `tests/integration/rls_test.dart` stubs

4. **Add Location Services**
   - [ ] Customer: Get H3 from GPS in NewOrderPage
   - [ ] Courier: Update current_h3_cell in real-time
   - [ ] Use `geolocator` or `location` package

5. **Improve Error Handling**
   - [ ] Add custom exception classes
   - [ ] Better error states in UI
   - [ ] Network error retry logic

### Medium Priority

6. **Implement Menu Management**
   - [ ] Merchant MenuManagementPage (from whitepaper §7)
   - [ ] CRUD operations for menu items
   - [ ] Volume/weight level selection

7. **Add Push Notifications**
   - [ ] Firebase Cloud Messaging setup
   - [ ] Order status change notifications
   - [ ] New order alerts for merchant

8. **Enhance E2E Tests**
   - [ ] Add test helper to create orders programmatically
   - [ ] Test all critical flows
   - [ ] Add screenshot capture on failure

9. **Add Analytics**
   - [ ] Track user events (order created, confirmed, etc.)
   - [ ] Performance monitoring
   - [ ] Error tracking (Sentry/Crashlytics)

10. **Internationalization**
    - [ ] Extract all hardcoded strings
    - [ ] Use `intl` package for i18n
    - [ ] Support EN + ZH (Traditional Chinese)

### Low Priority

11. **Dark Mode**
    - [ ] Extend AppTheme for dark mode
    - [ ] Theme switching logic

12. **Offline Support**
    - [ ] Local cache for orders
    - [ ] Sync when online
    - [ ] Offline indicators

13. **Performance Optimization**
    - [ ] Lazy loading for order lists
    - [ ] Image caching
    - [ ] Reduce bundle size

14. **Accessibility**
    - [ ] Semantic labels
    - [ ] Screen reader support
    - [ ] High contrast mode

15. **CI/CD Enhancements**
    - [ ] Add code coverage reporting
    - [ ] Automated version bumping
    - [ ] Deploy to TestFlight/Play Store beta

## 🐛 Known Issues

1. **Freezed Generation**: Must run `build_runner` before apps will compile
2. **Windows Script Permissions**: `chmod` doesn't work on Windows (fine for CI)
3. **Auth Stubs**: OTP Edge Functions not implemented yet
4. **RLS Test Stubs**: Need JWT tokens for different roles
5. **E2E Order Creation**: Need test helper function

## 📚 Reference

- [Flutter Docs](https://flutter.dev/docs)
- [Supabase Docs](https://supabase.com/docs)
- [Riverpod Docs](https://riverpod.dev)
- [Freezed Docs](https://pub.dev/packages/freezed)
- [H3 Docs](https://h3geo.org)

## 🎯 Success Checklist

- [ ] `melos bootstrap` completes successfully
- [ ] `melos run build:runner` generates all files
- [ ] `melos run analyze` shows no errors
- [ ] All unit tests pass
- [ ] Supabase starts and migrations apply
- [ ] Integration tests pass (with Supabase running)
- [ ] Newman API tests pass
- [ ] At least one app runs on device/simulator
- [ ] CI pipeline runs successfully (on GitHub)

---

**Current Status**: ✅ Scaffold complete, ready for `melos bootstrap` + `build_runner`



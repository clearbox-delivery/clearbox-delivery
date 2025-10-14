# Device Security & Simulator Policy

Purpose: Prevent account abuse by binding accounts to physical devices and blocking emulator/simulator usage in production. Provides development bypass for local testing.

## Policy Overview (per whitepapers Section 1.3)

### Production Requirements
1. **One device, one registration**: Each physical device can only register ONE account across all three apps.
2. **Device binding**: After first successful login/verification, the account is bound to that device.
3. **Simulator blocking**: Emulators/simulators cannot use the app in production.

### Account Uniqueness Rules
- One Email = One account (cross-app)
- One Phone = One account (cross-app)
- One Device = One account (cross-app)
- If a device logs into an existing account before registering, the device loses its one-time registration privilege.

## Implementation Strategy

### 1. Device Identification
**Method**: Generate UUID on first app launch, store in secure local storage.

**Storage**:
- Android: SharedPreferences (encrypted if available)
- iOS: Keychain
- Web/Dev: LocalStorage with fallback to session UUID

**Backend**: `user_devices` table tracks:
```sql
device_id TEXT PRIMARY KEY
user_id UUID (nullable until first bind)
first_seen_at TIMESTAMP
is_registered BOOLEAN
platform TEXT
```

### 2. Simulator/Emulator Detection (Production Only)

#### Android: Google Play Integrity API
- **Flow**:
  1. App requests integrity token at launch
  2. Send token to backend Edge Function `/verify-integrity`
  3. Backend calls Google Play Integrity API
  4. If `deviceIntegrity` verdict ≠ `MEETS_DEVICE_INTEGRITY`, block access
  
- **Implementation**: `flutter_play_integrity` package
- **Fallback**: If API unavailable, allow with warning log (graceful degradation)

#### iOS: App Attest + DeviceCheck
- **Flow**:
  1. App generates attestation key at launch
  2. Backend issues challenge
  3. App signs with key, returns assertion
  4. Backend validates via Apple DeviceCheck API

- **Implementation**: `app_attest` or native platform channels
- **Fallback**: If unavailable, allow with warning

#### Web: CAPTCHA
- **reCAPTCHA v3** or **Cloudflare Turnstile** on login/register
- Score threshold ≥ 0.7 to proceed
- Implementation: `flutter_recaptcha_v3` or web integration

### 3. Hardware Key (Optional Enhancement)
- Device generates asymmetric key pair in Secure Enclave (iOS) / Keystore (Android)
- Public key stored in backend
- Challenge-response on sensitive operations (payment, account changes)
- **Phase**: Post-MVP

### 4. Development Mode Bypass

**Environment Flag**: `ALLOW_DEV_MODE=true` (dart-define or .env)

**Behavior when enabled**:
- Skip simulator detection checks
- Allow multiple logins per device
- Show warning banner at top of app: "DEV MODE - Security checks bypassed"
- Log all security events to console

**How to enable**:
```bash
flutter run --dart-define=ALLOW_DEV_MODE=true \
            --dart-define=SUPABASE_URL=... \
            --dart-define=SUPABASE_ANON_KEY=...
```

**Default**: `ALLOW_DEV_MODE=false` (production strict mode)

## Backend Contract

### Edge Function: `/verify-device`
**Input**:
```json
{
  "device_id": "uuid",
  "integrity_token": "string (Android)",
  "attestation": "string (iOS)",
  "platform": "android|ios|web"
}
```

**Output**:
```json
{
  "allowed": boolean,
  "reason": "OK|SIMULATOR_DETECTED|INTEGRITY_FAILED|DEVICE_QUOTA_EXCEEDED"
}
```

### RPC: `bind_device_to_user`
```sql
FUNCTION bind_device_to_user(
  p_device_id TEXT,
  p_user_id UUID
) RETURNS BOOLEAN
```
- Checks if device already bound to another user → reject
- Checks if device already registered → reject
- Binds device, marks `is_registered=true`

### RPC: `mark_device_ineligible_if_login_on_existing_account`
```sql
FUNCTION mark_device_ineligible_if_login_on_existing_account(
  p_device_id TEXT,
  p_user_id UUID
) RETURNS VOID
```
- If the device has no prior registration binding and the user account already exists, mark this device as ineligible for future registration.

## Frontend Integration Points

### On App Launch
1. Generate/retrieve `deviceId` from local storage
2. If `ALLOW_DEV_MODE=true`, skip steps 3-4
3. Call device integrity check (platform-specific)
4. If failed, show error screen and exit

### On Login
1. Emulator detection: In production, block login on emulators/simulators if integrity/attest fails. In dev, bypass via env flag.
2. Device eligibility tracking: If this device has never registered and the user logs in to an existing account, mark this device as ineligible for future registration (per whitepaper 1.2). Do not block login due to binding.

### On Registration Complete
1. Call `bind_device_to_user(deviceId, newUserId)`
2. If fails (quota), show error
3. If succeeds, proceed to app

### UI Indicators
- **Dev mode**: Persistent banner at top (yellow background, "開發模式 - 安全檢查已略過")
- **Prod mode**: No banner; strict enforcement

## Security Considerations

### Attack Vectors Mitigated
- ✅ Mass account creation via emulators
- ✅ Account sharing across devices
- ✅ Bot/scraper abuse

### Known Limitations
- Rooted/jailbroken devices may bypass some checks (acceptable risk for MVP)
- Web version relies on CAPTCHA only (inherent limitation)
- Device factory reset allows new registration (acceptable; rare)

## Testing Strategy

### Dev Environment
- All checks bypassed with `ALLOW_DEV_MODE=true`
- Manual test buttons to simulate integrity failures

### CI/CD
- Tests run with dev mode enabled
- Integrity API calls mocked/stubbed

### Production Verification
- Monitor `user_devices` table for anomalies
- Alert on high registration rate from single IP
- Manual review flagged accounts

## Rollout Plan

### MVP (Phase 1.2)
- ✅ Device ID generation and storage
- ✅ Basic device binding check
- ✅ Dev mode bypass
- ⚠️ Simulator detection stubs (log-only)

### Post-MVP
- Full Play Integrity / App Attest integration
- CAPTCHA on web
- Hardware key challenge-response
- Real-time fraud monitoring

## References
- [Google Play Integrity API](https://developer.android.com/google/play/integrity)
- [Apple App Attest](https://developer.apple.com/documentation/devicecheck/preparing_to_use_the_app_attest_service)
- [Cloudflare Turnstile](https://developers.cloudflare.com/turnstile/)


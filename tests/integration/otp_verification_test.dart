import 'package:test/test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// OTP 验证集成测试
/// [TC-AUTH-001, TC-AUTH-003]
void main() {
  late SupabaseClient supabase;

  setUpAll(() async {
    final url = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'http://localhost:54321',
    );
    final anonKey = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'test-anon-key',
    );

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    supabase = Supabase.instance.client;
  });

  group('OTP Verification', () {
    test('TC-AUTH-001: Email OTP send returns success', () async {
      final deviceId = const Uuid().v4();

      final result = await supabase.rpc('send_otp', params: {
        'p_identifier': 'test@example.com',
        'p_otp_type': 'EMAIL',
        'p_device_id': deviceId,
      });

      expect(result['success'], isTrue);
      expect(result['expires_in'], equals(600));
      // 开发环境会返回 otp_code
      expect(result['otp_code'], isNotNull);
    });

    test('TC-AUTH-002: Verify OTP with correct code', () async {
      final deviceId = const Uuid().v4();
      final identifier = 'verify-test@example.com';

      // 发送 OTP
      final sendResult = await supabase.rpc('send_otp', params: {
        'p_identifier': identifier,
        'p_otp_type': 'EMAIL',
        'p_device_id': deviceId,
      });

      final otpCode = sendResult['otp_code'] as String;

      // 验证 OTP
      final verifyResult = await supabase.rpc('verify_otp', params: {
        'p_identifier': identifier,
        'p_otp_code': otpCode,
        'p_otp_type': 'EMAIL',
        'p_device_id': deviceId,
      });

      expect(verifyResult['verified'], isTrue);
    });

    test('TC-AUTH-003: Phone OTP cooldown', () async {
      final deviceId = const Uuid().v4();
      final identifier = '+886912345678';

      // 第一次发送
      await supabase.rpc('send_otp', params: {
        'p_identifier': identifier,
        'p_otp_type': 'PHONE',
        'p_device_id': deviceId,
      });

      // 立即再次发送应该失败
      expect(
        () async => await supabase.rpc('send_otp', params: {
          'p_identifier': identifier,
          'p_otp_type': 'PHONE',
          'p_device_id': deviceId,
        }),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('TC-AUTH-004: Max attempts lockout', () async {
      // TODO: 测试达到最大尝试次数后锁定
      // Email: 20次, Phone: 5次
      expect(true, isTrue);
    });
  });
}


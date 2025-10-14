import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// OTP Service
/// [REQ-AUTH-OTP-001] Email OTP: 30s cooldown, 20 attempts/device
/// [REQ-AUTH-OTP-002] Phone OTP: 120s cooldown, 5 attempts/device
class OTPService {
  final SupabaseClient _client;

  OTPService(this._client);

  /// Send OTP
  /// Returns success + remaining attempts or error
  Future<OTPSendResult> sendOTP({
    required String identifier,
    required OTPType otpType,
    required String deviceId,
  }) async {
    try {
      final response = await _client.rpc('send_otp', params: {
        'p_identifier': identifier,
        'p_otp_type': otpType.value,
        'p_device_id': deviceId,
      });

      final data = response as Map<String, dynamic>;
      return OTPSendResult(
        success: data['success'] == true,
        remainingAttempts: data['remaining_attempts'] as int?,
        errorMessage: data['error'] as String?,
        cooldownSeconds: data['cooldown_seconds'] as int?,
      );
    } catch (e) {
      return OTPSendResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Verify OTP
  Future<OTPVerifyResult> verifyOTP({
    required String identifier,
    required String otpCode,
    required OTPType otpType,
    required String deviceId,
  }) async {
    try {
      final response = await _client.rpc('verify_otp', params: {
        'p_identifier': identifier,
        'p_otp_code': otpCode,
        'p_otp_type': otpType.value,
        'p_device_id': deviceId,
      });

      final data = response as Map<String, dynamic>;
      return OTPVerifyResult(
        verified: data['verified'] == true,
        errorMessage: data['error'] as String?,
      );
    } catch (e) {
      return OTPVerifyResult(
        verified: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Get rate limit info for device
  Future<RateLimitInfo> getRateLimitInfo({
    required String deviceId,
    required OTPType otpType,
  }) async {
    try {
      final response = await _client
          .from('otp_rate_limits')
          .select()
          .eq('device_id', deviceId)
          .eq('otp_type', otpType.value)
          .maybeSingle();

      if (response == null) {
        return RateLimitInfo(
          attemptsUsed: 0,
          maxAttempts: otpType == OTPType.email ? 20 : 5,
          isLocked: false,
        );
      }

      final data = response as Map<String, dynamic>;
      final maxAttempts = otpType == OTPType.email ? 20 : 5;
      return RateLimitInfo(
        attemptsUsed: data['attempts_count'] as int? ?? 0,
        maxAttempts: maxAttempts,
        isLocked: (data['attempts_count'] as int? ?? 0) >= maxAttempts,
        lastAttemptAt: data['last_attempt_at'] != null
            ? DateTime.parse(data['last_attempt_at'] as String)
            : null,
      );
    } catch (e) {
      return RateLimitInfo(
        attemptsUsed: 0,
        maxAttempts: otpType == OTPType.email ? 20 : 5,
        isLocked: false,
      );
    }
  }
}

/// OTP Type enum
enum OTPType {
  email('EMAIL'),
  phone('PHONE');

  final String value;
  const OTPType(this.value);
}

/// Send OTP result
class OTPSendResult {
  final bool success;
  final int? remainingAttempts;
  final String? errorMessage;
  final int? cooldownSeconds;

  OTPSendResult({
    required this.success,
    this.remainingAttempts,
    this.errorMessage,
    this.cooldownSeconds,
  });
}

/// Verify OTP result
class OTPVerifyResult {
  final bool verified;
  final String? errorMessage;

  OTPVerifyResult({
    required this.verified,
    this.errorMessage,
  });
}

/// Rate limit info
class RateLimitInfo {
  final int attemptsUsed;
  final int maxAttempts;
  final bool isLocked;
  final DateTime? lastAttemptAt;

  RateLimitInfo({
    required this.attemptsUsed,
    required this.maxAttempts,
    required this.isLocked,
    this.lastAttemptAt,
  });

  int get remainingAttempts => maxAttempts - attemptsUsed;
  bool get canSend => !isLocked && remainingAttempts > 0;
}

/// OTP service provider
final otpServiceProvider = Provider<OTPService>((ref) {
  final client = ref.watch(supabaseProvider);
  return OTPService(client);
});


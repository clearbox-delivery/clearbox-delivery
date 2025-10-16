import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device Service
/// [docs/DEVICE_SECURITY.md] Device binding and simulator detection
/// Clarification: Do NOT block login based on binding. Follow policy:
/// - One device/email/phone may register only once.
/// - If an unregistered device logs in to an existing account, mark the device as ineligible for future registration.
/// Emulator login/registration is blocked in production via integrity/attest.
class DeviceService {
  final SupabaseClient _client;
  static const String _deviceIdKey = 'clearbox_device_id';

  DeviceService(this._client);

  /// Get or create device ID
  /// Persists across app launches
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Check if dev mode is enabled
  /// [docs/DEVICE_SECURITY.md] ALLOW_DEV_MODE bypass
  bool get isDevMode {
    const allowDevMode = String.fromEnvironment('ALLOW_DEV_MODE', defaultValue: 'false');
    return allowDevMode.toLowerCase() == 'true' || kDebugMode;
  }

  /// Check if device can be used for this user
  /// Returns true if:
  /// - Dev mode enabled, OR
  /// - Device not bound to any user, OR
  /// - Device bound to this specific user
  Future<DeviceCheckResult> checkDeviceBinding({
    required String deviceId,
    required String userId,
  }) async {
    // Dev mode bypass
    if (isDevMode) {
      return DeviceCheckResult(
        allowed: true,
        reason: 'DEV_MODE_BYPASS',
        isDevMode: true,
      );
    }

    try {
      // Check if device exists and its binding status
      final response = await _client
          .from('user_devices')
          .select()
          .eq('device_id', deviceId)
          .maybeSingle();

      if (response == null) {
        // New device, allowed
        return DeviceCheckResult(allowed: true, reason: 'NEW_DEVICE');
      }

      final data = response as Map<String, dynamic>;
      final boundUserId = data['user_id'] as String?;

      if (boundUserId == null) {
        // Device exists but not bound yet
        return DeviceCheckResult(allowed: true, reason: 'UNBOUND_DEVICE');
      }

      if (boundUserId == userId) {
        // Device bound to this user
        return DeviceCheckResult(allowed: true, reason: 'BOUND_TO_USER');
      }

      // Device bound to different user
      return DeviceCheckResult(
        allowed: false,
        reason: 'BOUND_TO_OTHER_USER',
        message: '此裝置已綁定其他帳號',
      );
    } catch (e) {
      // On error, allow in dev, block in prod
      return DeviceCheckResult(
        allowed: isDevMode,
        reason: 'ERROR',
        message: isDevMode ? '檢查失敗（dev模式允許）' : '裝置檢查失敗',
      );
    }
  }

  /// Bind device to user after successful registration/first login
  Future<DeviceBindResult> bindDeviceToUser({
    required String deviceId,
    required String userId,
  }) async {
    // Dev mode skip
    if (isDevMode) {
      return DeviceBindResult(success: true, isDevMode: true);
    }

    try {
      // Check if device already registered
      final existing = await _client
          .from('user_devices')
          .select()
          .eq('device_id', deviceId)
          .maybeSingle();

      if (existing != null) {
        final data = existing as Map<String, dynamic>;
        final isRegistered = data['is_registered'] == true;
        final boundUserId = data['user_id'] as String?;

        if (isRegistered && boundUserId != null && boundUserId != userId) {
          return DeviceBindResult(
            success: false,
            message: '此裝置已完成註冊，無法再次註冊',
          );
        }
      }

      // Bind device
      await _client.from('user_devices').upsert({
        'device_id': deviceId,
        'user_id': userId,
        'is_registered': true,
        'platform': _getPlatform(),
        'first_seen_at': DateTime.now().toIso8601String(),
      });

      return DeviceBindResult(success: true);
    } catch (e) {
      return DeviceBindResult(
        success: false,
        message: '綁定失敗: ${e.toString()}',
      );
    }
  }

  /// Record device seen (for tracking)
  Future<void> recordDeviceSeen(String deviceId) async {
    try {
      await _client.from('user_devices').upsert({
        'device_id': deviceId,
        'platform': _getPlatform(),
        'first_seen_at': DateTime.now().toIso8601String(),
      }, onConflict: 'device_id');
    } catch (e) {
      // Silently fail in dev
      if (kDebugMode) {
        print('Failed to record device: $e');
      }
    }
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }
}

/// Device check result
class DeviceCheckResult {
  final bool allowed;
  final String reason;
  final String? message;
  final bool isDevMode;

  DeviceCheckResult({
    required this.allowed,
    required this.reason,
    this.message,
    this.isDevMode = false,
  });
}

/// Device bind result
class DeviceBindResult {
  final bool success;
  final String? message;
  final bool isDevMode;

  DeviceBindResult({
    required this.success,
    this.message,
    this.isDevMode = false,
  });
}

/// Device service provider
final deviceServiceProvider = Provider<DeviceService>((ref) {
  final client = ref.watch(supabaseProvider);
  return DeviceService(client);
});

/// Current device ID provider
final deviceIdProvider = FutureProvider<String>((ref) async {
  final deviceService = ref.watch(deviceServiceProvider);
  return await deviceService.getDeviceId();
});


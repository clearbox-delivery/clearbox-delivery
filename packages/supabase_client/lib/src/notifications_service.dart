import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// Notifications Service
/// [docs/API_NOTIFICATIONS.md] Push and realtime notification handling
///
/// Dev mode: Supabase Realtime channels
/// Prod mode: TODO FCM integration
class NotificationsService {
  final SupabaseClient _client;
  RealtimeChannel? _channel;

  NotificationsService(this._client);

  /// Subscribe to notifications for a given user role and ID
  /// Role: 'merchant', 'customer', 'courier'
  Future<void> subscribe({
    required String role,
    required String userId,
    required Function(Map<String, dynamic>) onNotification,
  }) async {
    final channelName = 'notifications:$role:$userId';

    _channel = _client.channel(channelName);

    _channel!.onBroadcast(
      event: '*',
      callback: (payload) {
        // Validate payload has 'type' field
        if (payload is Map<String, dynamic> && payload.containsKey('type')) {
          onNotification(payload);
        }
      },
    );

    await _channel!.subscribe();
  }

  /// Unsubscribe from notifications
  Future<void> unsubscribe() async {
    if (_channel != null) {
      await _client.removeChannel(_channel!);
      _channel = null;
    }
  }

  /// Send notification (dev helper, backend should use this in prod via Edge Function)
  Future<void> sendNotification({
    required String role,
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final channelName = 'notifications:$role:$userId';
    final channel = _client.channel(channelName);

    await channel.subscribe();
    await channel.sendBroadcastMessage(
      event: payload['type'] as String,
      payload: payload,
    );
    await _client.removeChannel(channel);
  }
}

/// Notifications service provider
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  final client = ref.watch(supabaseProvider);
  return NotificationsService(client);
});


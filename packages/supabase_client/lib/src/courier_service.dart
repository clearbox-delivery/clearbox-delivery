import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

/// Courier service for profile and settings management
/// [REQ-COU-ACC-002] Courier account settings backend sync
class CourierService {
  final SupabaseClient _client;

  CourierService(this._client);

  /// Get courier settings (with fallback for missing fields)
  /// [TC-COU-ACC-004] Fetch courier settings
  Future<CourierSettings> getCourierSettings(String courierId) async {
    try {
      final response = await _client
          .from('couriers')
          .select('id, is_accepting_orders, push_enabled, display_name, vehicle_plate')
          .eq('id', courierId)
          .maybeSingle();

      if (response == null) {
        // Courier not found, return defaults
        return CourierSettings(
          courierId: courierId,
          isAcceptingOrders: true,
          pushEnabled: true,
        );
      }

      // Handle missing fields gracefully (minimal difference fallback)
      return CourierSettings(
        courierId: courierId,
        isAcceptingOrders: response['is_accepting_orders'] as bool? ?? true,
        pushEnabled: response['push_enabled'] as bool? ?? true,
        displayName: response['display_name'] as String?,
        vehiclePlate: response['vehicle_plate'] as String?,
      );
    } catch (e) {
      // If columns don't exist, return defaults
      return CourierSettings(
        courierId: courierId,
        isAcceptingOrders: true,
        pushEnabled: true,
      );
    }
  }

  /// Update courier settings
  /// [TC-COU-ACC-005] Update courier settings
  Future<bool> updateCourierSettings({
    required String courierId,
    bool? isAcceptingOrders,
    bool? pushEnabled,
    String? displayName,
    String? vehiclePlate,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (isAcceptingOrders != null) {
        updates['is_accepting_orders'] = isAcceptingOrders;
      }
      if (pushEnabled != null) {
        updates['push_enabled'] = pushEnabled;
      }
      if (displayName != null) {
        updates['display_name'] = displayName;
      }
      if (vehiclePlate != null) {
        updates['vehicle_plate'] = vehiclePlate;
      }

      if (updates.isEmpty) return true;

      await _client
          .from('couriers')
          .update(updates)
          .eq('id', courierId);

      return true;
    } catch (e) {
      // If columns don't exist, return false (minimal difference)
      return false;
    }
  }
}

/// Courier service provider
final courierServiceProvider = Provider<CourierService>((ref) {
  final client = ref.watch(supabaseProvider);
  return CourierService(client);
});


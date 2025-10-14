import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// Distance service for OSRM pre-calculated distances
/// [REQ-COU-FLOW-002] R/T sorting requires distance/ETA data
class DistanceService {
  final SupabaseClient _client;

  DistanceService(this._client);

  /// Get courier to merchant ETA in minutes
  /// Returns null if data not available (use fallback)
  /// [courier_app_whitepaper.md Section 4.2]
  Future<int?> getCourierToMerchantEta({
    required String courierH3,
    required String merchantH3,
  }) async {
    try {
      // TODO: Backend table 'h3_distance_matrix' not yet available
      // Expected schema: (from_h3, to_h3, distance_km, time_minutes)
      // For now, return null to trigger fallback
      return null;

      // Future implementation:
      // final response = await _client
      //     .from('h3_distance_matrix')
      //     .select('time_minutes')
      //     .eq('from_h3', courierH3)
      //     .eq('to_h3', merchantH3)
      //     .maybeSingle();
      // 
      // return response?['time_minutes'] as int?;
    } catch (e) {
      return null;
    }
  }

  /// Get merchant to customer ETA in minutes
  /// Returns null if data not available (use fallback)
  Future<int?> getMerchantToCustomerEta({
    required String merchantH3,
    required String customerH3,
  }) async {
    try {
      // TODO: Backend table not yet available
      return null;

      // Future implementation: same as above
    } catch (e) {
      return null;
    }
  }

  /// Calculate k-ring distance (H3 cells apart)
  /// For k=40 filtering
  int getH3Distance(String h3a, String h3b) {
    // TODO: Implement H3 distance calculation
    // For now, allow all (return 0)
    return 0;
  }
}

/// Distance service provider
final distanceServiceProvider = Provider<DistanceService>((ref) {
  final client = ref.watch(supabaseProvider);
  return DistanceService(client);
});


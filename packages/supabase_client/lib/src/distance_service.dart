import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// Distance service for OSRM pre-calculated distances
/// [REQ-COU-FLOW-002] R/T sorting requires distance/ETA data
/// [REQ-COU-FLOW-005] Batch queries and LRU cache
class DistanceService {
  final SupabaseClient _client;
  final _cache = <String, _CacheEntry>{};
  static const _maxCacheSize = 500;
  static const _cacheTTL = Duration(minutes: 30);

  DistanceService(this._client);

  /// Get courier to merchant ETA in minutes
  /// Returns null if data not available (use fallback)
  /// [courier_app_whitepaper.md Section 4.2]
  /// [REQ-COU-FLOW-004] Enable real OSRM distance data
  Future<int?> getCourierToMerchantEta({
    required String courierH3,
    required String merchantH3,
  }) async {
    try {
      // Attempt to query h3_distance_matrix table
      // Expected schema: (from_h3 text, to_h3 text, time_minutes int, distance_km real)
      // Index: (from_h3, to_h3) unique
      final response = await _client
          .from('h3_distance_matrix')
          .select('time_minutes')
          .eq('from_h3', courierH3)
          .eq('to_h3', merchantH3)
          .maybeSingle();

      return response?['time_minutes'] as int?;
    } catch (e) {
      // Table doesn't exist or query failed
      // Return null to trigger fallback (5min default in RTCalculator)
      return null;
    }
  }

  /// Get merchant to customer ETA in minutes
  /// Returns null if data not available (use fallback)
  /// [REQ-COU-FLOW-004] Enable real OSRM distance data
  Future<int?> getMerchantToCustomerEta({
    required String merchantH3,
    required String customerH3,
  }) async {
    try {
      final response = await _client
          .from('h3_distance_matrix')
          .select('time_minutes')
          .eq('from_h3', merchantH3)
          .eq('to_h3', customerH3)
          .maybeSingle();

      return response?['time_minutes'] as int?;
    } catch (e) {
      // Table doesn't exist or query failed
      // Return null to trigger fallback (5min default in RTCalculator)
      return null;
    }
  }

  /// Batch query ETAs for multiple H3 pairs
  /// [REQ-COU-FLOW-005] Reduce Supabase requests
  /// Returns Map<"from->to", time_minutes?>
  Future<Map<String, int?>> getBatchETA({
    required List<({String from, String to})> pairs,
  }) async {
    if (pairs.isEmpty) return {};

    final result = <String, int?>{};
    final uncachedPairs = <({String from, String to})>[];

    // Check cache first
    for (final pair in pairs) {
      final key = '${pair.from}->${pair.to}';
      final cached = _getCached(key);
      if (cached != null) {
        result[key] = cached;
      } else {
        uncachedPairs.add(pair);
      }
    }

    // Batch query uncached pairs
    if (uncachedPairs.isNotEmpty) {
      try {
        final pairsJson = uncachedPairs
            .map((p) => {'from_h3': p.from, 'to_h3': p.to})
            .toList();

        final response = await _client.rpc('get_batch_eta', params: {
          'p_pairs': pairsJson,
        }) as List;

        for (final row in response) {
          final fromH3 = row['from_h3'] as String;
          final toH3 = row['to_h3'] as String;
          final timeMinutes = row['time_minutes'] as int?;
          final key = '$fromH3->$toH3';
          
          _putCache(key, timeMinutes);
          result[key] = timeMinutes;
        }

        // Mark missing pairs as null (cache negative results)
        for (final pair in uncachedPairs) {
          final key = '${pair.from}->${pair.to}';
          if (!result.containsKey(key)) {
            _putCache(key, null);
            result[key] = null;
          }
        }
      } catch (e) {
        // RPC not available or query failed, return nulls
        for (final pair in uncachedPairs) {
          final key = '${pair.from}->${pair.to}';
          result[key] = null;
        }
      }
    }

    return result;
  }

  int? _getCached(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Check TTL
    if (DateTime.now().difference(entry.timestamp) > _cacheTTL) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value;
  }

  void _putCache(String key, int? value) {
    // Simple LRU: remove oldest if cache full
    if (_cache.length >= _maxCacheSize) {
      final oldestKey = _cache.entries
          .reduce((a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b)
          .key;
      _cache.remove(oldestKey);
    }
    
    _cache[key] = _CacheEntry(value: value, timestamp: DateTime.now());
  }

  /// Clear cache (for testing or manual refresh)
  void clearCache() {
    _cache.clear();
  }
}

class _CacheEntry {
  final int? value;
  final DateTime timestamp;

  _CacheEntry({required this.value, required this.timestamp});
}

/// Distance service provider
final distanceServiceProvider = Provider<DistanceService>((ref) {
  final client = ref.watch(supabaseProvider);
  return DistanceService(client);
});


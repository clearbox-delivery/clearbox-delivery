import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// Realtime service for order updates
/// [REQ-MER-CO-002] Orders visible within 2s
class RealtimeService {
  final SupabaseClient _client;

  RealtimeService(this._client);

  /// Watch merchant orders with realtime updates
  /// [TC-MER-E2E-001]
  Stream<List<Order>> watchMerchantOrders({
    required String merchantId,
    OrderStatus? status,
  }) {
    var query = _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('merchant_id', merchantId);

    if (status != null) {
      query = query.eq('status', status.value);
    }

    return query
        .order('created_at')
        .map((rows) => rows
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Watch available orders for courier
  Stream<List<Order>> watchAvailableOrders({String? h3Cell}) {
    var query = _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', OrderStatus.waitingCourier.value);

    if (h3Cell != null) {
      query = query.eq('h3_merchant', h3Cell);
    }

    return query
        .order('created_at')
        .map((rows) => rows
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Watch specific order updates
  Stream<Order?> watchOrder(String orderId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return Order.fromJson(rows.first as Map<String, dynamic>);
        });
  }
}

/// Realtime service provider
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final client = ref.watch(supabaseProvider);
  return RealtimeService(client);
});

/// Merchant orders stream provider
/// [REQ-MER-CO-002]
final merchantOrdersStreamProvider = StreamProvider.family<List<Order>, MerchantOrdersQuery>(
  (ref, query) {
    final realtimeService = ref.watch(realtimeServiceProvider);
    return realtimeService.watchMerchantOrders(
      merchantId: query.merchantId,
      status: query.status,
    );
  },
);

class MerchantOrdersQuery {
  final String merchantId;
  final OrderStatus? status;

  MerchantOrdersQuery({
    required this.merchantId,
    this.status,
  });
}



import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

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
    final stream = _client
        .from('orders')
        .stream(primaryKey: ['id']);

    // Some versions of supabase_flutter do not support `.eq` chaining on streams.
    // Filter client-side to maintain compatibility.
    return stream
        .map((rows) => rows
            .where((row) {
              final matchesMerchant = row['merchant_id'] == merchantId;
              final matchesStatus = status == null || row['status'] == status.value;
              return matchesMerchant && matchesStatus;
            })
            .toList())
        .map((rows) => rows
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Watch available orders for courier
  Stream<List<Order>> watchAvailableOrders({String? h3Cell}) {
    final stream = _client
        .from('orders')
        .stream(primaryKey: ['id']);

    return stream
        .map((rows) => rows
            .where((row) {
              final matchesStatus = row['status'] == OrderStatus.waitingCourier.value;
              final matchesH3 = h3Cell == null || row['h3_merchant'] == h3Cell;
              return matchesStatus && matchesH3;
            })
            .toList())
        .map((rows) => rows
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Watch specific order updates
  Stream<Order?> watchOrder(String orderId) {
    final stream = _client
        .from('orders')
        .stream(primaryKey: ['id']);

    return stream.map((rows) {
      if (rows.isEmpty) return null;
      final match = rows.firstWhere(
        (row) => row['id'] == orderId,
        orElse: () => {},
      );
      if (match.isEmpty) return null;
      return Order.fromJson(match as Map<String, dynamic>);
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



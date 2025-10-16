import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';

/// Order service for order operations
/// [REQ-CUST-ORDER-001, REQ-MER-CO-001, REQ-COU-MATCH-003]
class OrderService {
  final SupabaseClient _client;

  OrderService(this._client);

  /// Create new order
  Future<Order> createOrder({
    required String merchantId,
    required List<OrderItem> items,
    required double deliveryPrice,
    String? h3Customer,
    String? customerNotes,
  }) async {
    final response = await _client.rpc('create_order', params: {
      'p_merchant_id': merchantId,
      'p_items': items.map((e) => e.toJson()).toList(),
      'p_delivery_price': deliveryPrice,
      'p_h3_customer': h3Customer,
      'p_customer_notes': customerNotes,
    });
    return Order.fromJson(response as Map<String, dynamic>);
  }

  /// Merchant confirms order
  Future<Order> merchantConfirm({
    required String orderId,
    required bool stockOk,
    required bool volumeOk,
    required int prepMinutes,
    String? note,
  }) async {
    final response = await _client.rpc('merchant_confirm', params: {
      'p_order_id': orderId,
      'p_stock_ok': stockOk,
      'p_volume_ok': volumeOk,
      'p_prep_minutes': prepMinutes,
      'p_note': note ?? '',
    });
    return Order.fromJson(response as Map<String, dynamic>);
  }

  Future<void> merchantCancel({required String orderId, required String reason}) async {
    await _client.rpc('merchant_cancel', params: {
      'p_order_id': orderId,
      'p_cancel_reason': reason,
    });
  }

  Future<void> merchantAdjustPrepTime({required String orderId, required int deltaMinutes}) async {
    await _client.rpc('merchant_adjust_prep_time', params: {
      'p_order_id': orderId,
      'p_delta_minutes': deltaMinutes,
    });
  }

  Future<void> merchantPrepReady({required String orderId}) async {
    await _client.rpc('merchant_prep_ready', params: {'p_order_id': orderId});
  }

  Future<void> merchantExtendPrepTime({required String orderId, required int plusMinutes}) async {
    await _client.rpc('merchant_extend_prep_time', params: {
      'p_order_id': orderId,
      'p_plus_minutes': plusMinutes,
    });
  }

  /// Courier accepts order (atomic)
  Future<OrderAcceptResult> acceptOrder(String orderId) async {
    try {
      final response = await _client.rpc('accept_order', params: {
        'p_order_id': orderId,
      }) as Map<String, dynamic>;
      if (response['success'] != true) {
        return OrderAcceptResult(
          success: false,
          errorCode: response['error_code'] as String?,
          message: response['message'] as String?,
        );
      }
      return OrderAcceptResult(
        success: true,
        order: Order.fromJson(response['order'] as Map<String, dynamic>),
      );
    } catch (e) {
      return OrderAcceptResult(success: false, errorCode: 'ERR_UNKNOWN', message: '$e');
    }
  }

  /// Mark delivered
  Future<void> markDelivered({required String orderId, String? deliveryPhotoUrl}) async {
    final response = await _client.rpc('mark_delivered', params: {
      'p_order_id': orderId,
      'p_delivery_photo_url': deliveryPhotoUrl,
    }) as Map<String, dynamic>;
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to mark delivered');
    }
  }

  /// Queries
  Future<Order?> getOrder(String orderId) async {
    final response = await _client.from('orders').select().eq('id', orderId).maybeSingle();
    if (response == null) return null;
    return Order.fromJson(response);
  }

  Future<List<Order>> getCustomerOrders(String customerId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return (response as List).map((j) => Order.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Order>> getMerchantOrders({required String merchantId, OrderStatus? status}) async {
    var query = _client.from('orders').select().eq('merchant_id', merchantId);
    if (status != null) query = query.eq('status', status.value);
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((j) => Order.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Order>> getAvailableOrders({String? h3Cell}) async {
    var query = _client.from('orders').select().eq('status', OrderStatus.waitingCourier.value);
    if (h3Cell != null) query = query.eq('h3_merchant', h3Cell);
    final response = await query.order('created_at', ascending: false);
    return (response as List).map((j) => Order.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<OrderEvent>> getOrderEvents(String orderId) async {
    final response = await _client
        .from('order_events')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: true);
    return (response as List).map((j) => OrderEvent.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Order>> getHistoricalOrders({
    required String merchantId,
    required String timeRange,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    DateTime rangeStart;
    switch (timeRange) {
      case 'today':
        rangeStart = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        rangeStart = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        rangeStart = DateTime(now.year, now.month, 1);
        break;
      case 'custom':
        rangeStart = startDate ?? now.subtract(const Duration(days: 30));
        break;
      default:
        rangeStart = now.subtract(const Duration(days: 7));
    }

    final response = await _client
        .from('orders')
        .select()
        .eq('merchant_id', merchantId)
        .inFilter('status', [
          OrderStatus.delivered.value,
          OrderStatus.cancelledMerchant.value,
          OrderStatus.cancelledCustomer.value,
          OrderStatus.cancelledCourier.value,
          OrderStatus.expiredUnmatched.value,
        ])
        .gte('created_at', rangeStart.toIso8601String())
        .order('created_at', ascending: false);
    return (response as List).map((j) => Order.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Order>> getCourierHistory({
    required String courierId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
        .from('orders')
        .select()
        .eq('courier_id', courierId)
        .inFilter('status', [
          OrderStatus.delivered.value,
          OrderStatus.cancelledCustomer.value,
          OrderStatus.cancelledMerchant.value,
          OrderStatus.cancelledCourier.value,
        ]);
    if (from != null) query = query.gte('updated_at', from.toIso8601String());
    if (to != null) query = query.lte('updated_at', to.toIso8601String());
    final response = await query.order('updated_at', ascending: false);
    return (response as List).map((j) => Order.fromJson(j)).toList();
  }

  /// Verification
  Future<bool> verifyPickupCode({required String orderId, required String code}) async {
    try {
      final result = await _client.rpc('verify_pickup_code', params: {
        'p_order_id': orderId,
        'p_code': code,
      }) as bool;
      return result;
    } catch (_) {
      return code.length == 6;
    }
  }

  Future<String?> regeneratePickupCode({required String orderId}) async {
    try {
      final newCode = await _client.rpc('regenerate_pickup_code', params: {
        'p_order_id': orderId,
      }) as String;
      return newCode;
    } catch (_) {
      return null;
    }
  }
}

class OrderAcceptResult {
  final bool success;
  final Order? order;
  final String? errorCode;
  final String? message;

  OrderAcceptResult({
    required this.success,
    this.order,
    this.errorCode,
    this.message,
  });
}

/// Order service provider
final orderServiceProvider = Provider<OrderService>((ref) {
  final client = ref.watch(supabaseProvider);
  return OrderService(client);
});



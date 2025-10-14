import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// Order service for order operations
/// [REQ-CUST-ORDER-001, REQ-MER-CO-001, REQ-COU-MATCH-003]
class OrderService {
  final SupabaseClient _client;

  OrderService(this._client);

  /// Create new order
  /// [TC-CUST-001, TC-CUST-002]
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

  /// Merchant confirms order (extended with stock and volume checks)
  /// [TC-MER-CO-001] [merchant_app_whitepaper.md Section 4.1]
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

  /// Merchant cancels order with reason
  /// [merchant_app_whitepaper.md Section 4.1]
  Future<void> merchantCancel({
    required String orderId,
    required String reason,
  }) async {
    await _client.rpc('merchant_cancel', params: {
      'p_order_id': orderId,
      'p_cancel_reason': reason,
    });
  }

  /// Merchant adjusts prep time (±5 minutes)
  /// [merchant_app_whitepaper.md Section 4.2]
  Future<void> merchantAdjustPrepTime({
    required String orderId,
    required int deltaMinutes,
  }) async {
    await _client.rpc('merchant_adjust_prep_time', params: {
      'p_order_id': orderId,
      'p_delta_minutes': deltaMinutes,
    });
  }

  /// Merchant marks prep ready (可取餐)
  /// [merchant_app_whitepaper.md Section 4.3]
  Future<void> merchantPrepReady({
    required String orderId,
  }) async {
    await _client.rpc('merchant_prep_ready', params: {
      'p_order_id': orderId,
    });
  }

  /// Merchant extends prep time (+5/+10 minutes)
  /// [merchant_app_whitepaper.md Section 4.3]
  Future<void> merchantExtendPrepTime({
    required String orderId,
    required int plusMinutes,
  }) async {
    await _client.rpc('merchant_extend_prep_time', params: {
      'p_order_id': orderId,
      'p_plus_minutes': plusMinutes,
    });
  }

  /// Courier accepts order (atomic with conflict handling)
  /// [TC-COU-ACPT-001]
  Future<AcceptOrderResult> acceptOrder(String orderId) async {
    try {
      // TODO: Backend RPC not yet available, use REST update
      // Once backend ready, switch to RPC for atomic conflict handling
      final response = await _client
          .from('orders')
          .update({'status': OrderStatus.courierAssigned.value})
          .eq('id', orderId)
          .eq('status', OrderStatus.waitingCourier.value) // Optimistic lock
          .select()
          .single();

      return AcceptOrderResult(
        success: true,
        order: Order.fromJson(response as Map<String, dynamic>),
      );
    } on PostgrestException catch (e) {
      if (e.code == '406' || e.message.contains('0 rows')) {
        return AcceptOrderResult(
          success: false,
          errorCode: 'ERR_ALREADY_ASSIGNED',
          message: 'Order has already been accepted by another courier',
        );
      }
      rethrow;
    }
  }

  /// Mark order as delivered
  /// [REQ-COU-FLOW-004]
  Future<void> markDelivered({required String orderId}) async {
    // TODO: Backend RPC not yet available, use REST update
    await _client
        .from('orders')
        .update({'status': OrderStatus.delivered.value})
        .eq('id', orderId);
  }

  /// Get order by ID
  Future<Order?> getOrder(String orderId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('id', orderId)
        .maybeSingle();

    if (response == null) return null;
    return Order.fromJson(response);
  }

  /// Get orders for customer
  /// [TC-RLS-001]
  Future<List<Order>> getCustomerOrders(String customerId) async {
    final response = await _client
        .from('orders')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get orders for merchant with specific status
  Future<List<Order>> getMerchantOrders({
    required String merchantId,
    OrderStatus? status,
  }) async {
    var query = _client
        .from('orders')
        .select()
        .eq('merchant_id', merchantId);

    if (status != null) {
      query = query.eq('status', status.value);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get available orders for courier (WAITING_COURIER status)
  Future<List<Order>> getAvailableOrders({String? h3Cell}) async {
    var query = _client
        .from('orders')
        .select()
        .eq('status', OrderStatus.waitingCourier.value);

    if (h3Cell != null) {
      // Filter by H3 proximity (handled by RLS/RPC)
      query = query.eq('h3_merchant', h3Cell);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List)
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get order events for audit trail
  /// [TC-AUDIT-001]
  Future<List<OrderEvent>> getOrderEvents(String orderId) async {
    final response = await _client
        .from('order_events')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: true);

    return (response as List)
        .map((json) => OrderEvent.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get historical orders for merchant (completed, cancelled, expired)
  /// [REQ-MER-HIS-001] [merchant_app_whitepaper.md Section 5.1]
  Future<List<Order>> getHistoricalOrders({
    required String merchantId,
    required String timeRange, // 'today', 'week', 'month', 'custom'
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Calculate time range
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

    // Query historical orders (DELIVERED, CANCELLED_*, EXPIRED_UNMATCHED)
    final response = await _client
        .from('orders')
        .select()
        .eq('merchant_id', merchantId)
        .in_('status', [
          OrderStatus.delivered.value,
          OrderStatus.cancelledMerchant.value,
          OrderStatus.cancelledCustomer.value,
          OrderStatus.cancelledCourier.value,
          OrderStatus.expiredUnmatched.value,
        ])
        .gte('created_at', rangeStart.toIso8601String())
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

class AcceptOrderResult {
  final bool success;
  final Order? order;
  final String? errorCode;
  final String? message;

  AcceptOrderResult({
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



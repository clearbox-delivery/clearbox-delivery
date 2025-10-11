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

  /// Merchant confirms order
  /// [TC-MER-CO-001]
  Future<Order> merchantConfirmOrder({
    required String orderId,
    required int prepTimeMinutes,
    String? merchantNotes,
  }) async {
    final response = await _client.rpc('merchant_confirm_order', params: {
      'p_order_id': orderId,
      'p_prep_time_minutes': prepTimeMinutes,
      'p_merchant_notes': merchantNotes,
    });

    return Order.fromJson(response as Map<String, dynamic>);
  }

  /// Courier accepts order (atomic with conflict handling)
  /// [TC-COU-ACPT-001]
  Future<AcceptOrderResult> acceptOrder(String orderId) async {
    try {
      final response = await _client.rpc('accept_order', params: {
        'p_order_id': orderId,
      });

      return AcceptOrderResult(
        success: true,
        order: Order.fromJson(response as Map<String, dynamic>),
      );
    } on PostgrestException catch (e) {
      if (e.code == '409' || e.message.contains('already assigned')) {
        return AcceptOrderResult(
          success: false,
          errorCode: 'ERR_ALREADY_ASSIGNED',
          message: 'Order has already been accepted by another courier',
        );
      }
      rethrow;
    }
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



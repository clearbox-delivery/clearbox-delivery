import 'package:test/test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Integration tests for order lifecycle
/// [TC-MER-CO-001, TC-AUDIT-001]
///
/// NOTE: These tests require a running Supabase instance
/// Run: `supabase start` before executing
void main() {
  late SupabaseClient supabase;
  final testOrderIds = <String>[];

  setUpAll(() async {
    final url = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'http://localhost:54321',
    );
    final anonKey = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'test-anon-key',
    );

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    supabase = Supabase.instance.client;
  });

  tearDownAll(() async {
    // Cleanup test orders
    for (final orderId in testOrderIds) {
      await supabase.from('orders').delete().eq('id', orderId);
    }
  });

  group('Order Flow Integration', () {
    test('TC-MER-CO-001: Merchant confirms order → status WAITING_COURIER',
        () async {
      // Create pending order
      final createResult = await supabase.rpc('create_order', params: {
        'p_merchant_id': '00000000-0000-0000-0000-000000000002',
        'p_items': [
          {'sku': 'test-001', 'name': 'Test Item', 'quantity': 1, 'unit_price': 100}
        ],
        'p_delivery_price': 45,
        'p_customer_notes': 'Integration test order',
      });

      expect(createResult, isNotNull);
      expect(createResult['status'], equals('PENDING_STORE_CONFIRM'));
      
      final orderId = createResult['id'] as String;
      testOrderIds.add(orderId);

      // Merchant confirms
      final confirmResult = await supabase.rpc('merchant_confirm_order', params: {
        'p_order_id': orderId,
        'p_prep_time_minutes': 15,
        'p_merchant_notes': 'Confirmed',
      });

      expect(confirmResult, isNotNull);
      expect(confirmResult['status'], equals('WAITING_COURIER'));
      expect(confirmResult['prep_time_minutes'], equals(15));
    });

    test('TC-AUDIT-001: Event audit trail records all transitions', () async {
      // Create order
      final order = await supabase.rpc('create_order', params: {
        'p_merchant_id': '00000000-0000-0000-0000-000000000002',
        'p_items': [
          {'sku': 'test-002', 'name': 'Test Item', 'quantity': 1, 'unit_price': 100}
        ],
        'p_delivery_price': 50,
      });

      final orderId = order['id'] as String;
      testOrderIds.add(orderId);

      // Confirm order
      await supabase.rpc('merchant_confirm_order', params: {
        'p_order_id': orderId,
        'p_prep_time_minutes': 20,
      });

      // Check events
      final events = await supabase
          .from('order_events')
          .select()
          .eq('order_id', orderId)
          .order('created_at', ascending: true);

      expect(events.length, greaterThanOrEqualTo(2));
      
      // First event: ORDER_CREATED
      expect(events[0]['event_type'], equals('ORDER_CREATED'));
      expect(events[0]['to_status'], equals('PENDING_STORE_CONFIRM'));
      
      // Second event: MERCHANT_CONFIRMED
      expect(events[1]['event_type'], equals('MERCHANT_CONFIRMED'));
      expect(events[1]['from_status'], equals('PENDING_STORE_CONFIRM'));
      expect(events[1]['to_status'], equals('WAITING_COURIER'));
    });

    test('TC-CUST-002: Invalid delivery price returns error', () async {
      expect(
        () async => await supabase.rpc('create_order', params: {
          'p_merchant_id': '00000000-0000-0000-0000-000000000002',
          'p_items': [
            {'sku': 'test-003', 'name': 'Test', 'quantity': 1, 'unit_price': 100}
          ],
          'p_delivery_price': 0, // Below minimum
        }),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}



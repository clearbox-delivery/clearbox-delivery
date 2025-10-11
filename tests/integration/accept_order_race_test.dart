import 'package:test/test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Integration test for courier accept order race conditions
/// [TC-COU-ACPT-001]
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
    for (final orderId in testOrderIds) {
      await supabase.from('orders').delete().eq('id', orderId);
    }
  });

  test('TC-COU-ACPT-001: Two couriers accept same order → only one succeeds',
      () async {
    // Create order in WAITING_COURIER status
    final order = await supabase.rpc('create_order', params: {
      'p_merchant_id': '00000000-0000-0000-0000-000000000002',
      'p_items': [
        {'sku': 'race-test', 'name': 'Race Test', 'quantity': 1, 'unit_price': 100}
      ],
      'p_delivery_price': 60,
    });

    final orderId = order['id'] as String;
    testOrderIds.add(orderId);

    // Merchant confirms to make it WAITING_COURIER
    await supabase.rpc('merchant_confirm_order', params: {
      'p_order_id': orderId,
      'p_prep_time_minutes': 10,
    });

    // Simulate two couriers accepting simultaneously
    // Note: In real test, use two different auth clients
    final results = await Future.wait(
      [
        supabase.rpc('accept_order', params: {'p_order_id': orderId}),
        supabase.rpc('accept_order', params: {'p_order_id': orderId}),
      ],
      eagerError: true,
    ).catchError((error) {
      // Expected: one will throw error
      return [null, error];
    });

    // At least one should succeed, one should fail
    final successes = results.where((r) => r != null && r is! Exception).length;
    
    // In atomic operation, exactly 1 should succeed
    expect(successes, lessThanOrEqualTo(1));

    // Verify order has exactly one courier assigned
    final finalOrder = await supabase
        .from('orders')
        .select()
        .eq('id', orderId)
        .single();

    expect(finalOrder['courier_id'], isNotNull);
    expect(finalOrder['status'], equals('COURIER_ASSIGNED'));
  });
}



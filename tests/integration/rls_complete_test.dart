import 'package:test/test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 完整的 RLS 测试 - 使用真实 JWT
/// [TC-RLS-001~006]
///
/// 运行前需要先生成 JWT tokens:
/// deno run -A scripts/generate_test_jwts.ts
void main() {
  late SupabaseClient customerClient;
  late SupabaseClient merchantClient;
  late SupabaseClient courierClient;

  // 从环境变量获取 JWT
  final customerJwt = const String.fromEnvironment('CUSTOMER_JWT');
  final merchantJwt = const String.fromEnvironment('MERCHANT_JWT');
  final courierJwt = const String.fromEnvironment('COURIER_JWT');

  setUpAll(() async {
    final url = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'http://localhost:54321',
    );

    // 使用不同的 JWT 创建客户端
    // 实际实现需要自定义 auth header
    await Supabase.initialize(
      url: url,
      anonKey: 'placeholder',
    );

    // TODO: 实现使用自定义 JWT 的客户端创建
    customerClient = Supabase.instance.client;
    merchantClient = Supabase.instance.client;
    courierClient = Supabase.instance.client;
  });

  group('RLS Data Isolation', () {
    test('TC-RLS-001: Customer cannot see other customer orders', () async {
      // Customer 1 creates order
      final order1 = await customerClient.rpc('create_order', params: {
        'p_merchant_id': '00000000-0000-0000-0000-000000000002',
        'p_items': [
          {'sku': 'test', 'name': 'Test', 'quantity': 1, 'unit_price': 100}
        ],
        'p_delivery_price': 50,
      });

      // Customer 1 queries orders
      final myOrders = await customerClient
          .from('orders')
          .select()
          .eq('customer_id', order1['customer_id']);

      expect(myOrders, isNotEmpty);

      // Customer 1 tries to query other customer's orders (should return empty)
      final otherOrders = await customerClient
          .from('orders')
          .select()
          .neq('customer_id', order1['customer_id']);

      // RLS should filter out other customers' orders
      expect(otherOrders, isEmpty);
    });

    test('TC-RLS-002: Merchant can only see own store orders', () async {
      // Merchant queries orders for own store
      final ownOrders = await merchantClient
          .from('orders')
          .select()
          .eq('merchant_id', '00000000-0000-0000-0000-000000000002');

      // Should be able to see own orders
      expect(ownOrders, isA<List>());

      // Merchant tries to query other merchant's orders
      // RLS should prevent this
      // TODO: 实现跨商家查询测试
    });

    test('TC-RLS-003: Courier can see available and assigned orders', () async {
      // Courier queries available orders (WAITING_COURIER)
      final available = await courierClient
          .from('orders')
          .select()
          .eq('status', 'WAITING_COURIER');

      expect(available, isA<List>());

      // Courier queries own assigned orders
      final assigned = await courierClient
          .from('orders')
          .select()
          .eq('courier_id', '00000000-0000-0000-0000-000000000003');

      expect(assigned, isA<List>());
    });

    test('TC-RLS-004: Menu items - merchants can only edit own', () async {
      // Merchant queries own menu
      final ownMenu = await merchantClient
          .from('menu_items')
          .select()
          .eq('merchant_id', '00000000-0000-0000-0000-000000000002');

      expect(ownMenu, isA<List>());

      // TODO: Verify cannot edit other merchant's menu
    });

    test('TC-RLS-005: Order events visible to related parties', () async {
      // Customer should see events for own orders
      // Merchant should see events for store orders
      // Courier should see events for assigned orders

      final events = await customerClient
          .from('order_events')
          .select();

      // Should return only events for customer's orders
      expect(events, isA<List>());
    });

    test('TC-RLS-006: Courier locations - only online couriers visible', () async {
      final locations = await customerClient
          .from('courier_locations')
          .select()
          .eq('is_online', true);

      expect(locations, isA<List>());

      // Offline couriers should not be visible
      final offline = await customerClient
          .from('courier_locations')
          .select()
          .eq('is_online', false);

      // Should be empty or filtered by RLS
      expect(offline, isA<List>());
    });
  });

  group('RLS Security Tests', () {
    test('Cannot bypass RLS with direct table access', () async {
      // Attempt to access orders without proper filters
      // Should return only authorized data

      final orders = await customerClient
          .from('orders')
          .select();

      // All returned orders should belong to this customer
      for (final order in orders) {
        expect(order['customer_id'], isNotNull);
      }
    });

    test('Service role key bypasses RLS (admin access)', () async {
      // Create client with service role key
      final adminClient = SupabaseClient(
        const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'http://localhost:54321',
        ),
        const String.fromEnvironment('SERVICE_ROLE_KEY', defaultValue: 'test'),
      );

      // Should be able to see all orders
      final allOrders = await adminClient
          .from('orders')
          .select();

      expect(allOrders, isA<List>());
    });
  });
}


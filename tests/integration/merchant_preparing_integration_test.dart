import 'dart:convert';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

/// Integration tests for merchant preparing RPCs
/// [TC-MER-PREP-READY-001] merchant_prep_ready RPC
/// [TC-MER-EXTEND-INT-001] merchant_extend_prep_time RPC
/// [merchant_app_whitepaper.md Section 4.3]
/// [REQ-MER-CO-003]
///
/// Note: These tests require Supabase Local to be running.
/// Run: supabase start
/// Then: dart test tests/integration/merchant_preparing_integration_test.dart

void main() {
  late String baseUrl;
  late String anonKey;
  late String testOrderId;
  late String merchantJwt;
  late String otherMerchantJwt;

  setUpAll(() async {
    baseUrl = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'http://127.0.0.1:54321',
    );
    anonKey = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
    );

    // Sign up test merchant
    final merchantEmail = 'test-merchant-prep-${DateTime.now().millisecondsSinceEpoch}@test.com';
    final merchantSignup = await http.post(
      Uri.parse('$baseUrl/auth/v1/signup'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': anonKey,
      },
      body: jsonEncode({
        'email': merchantEmail,
        'password': 'TestPassword123!',
      }),
    );

    final merchantData = jsonDecode(merchantSignup.body);
    merchantJwt = merchantData['access_token'];
    final merchantId = merchantData['user']['id'];

    // Sign up another merchant for RLS testing
    final otherEmail = 'test-other-merchant-${DateTime.now().millisecondsSinceEpoch}@test.com';
    final otherSignup = await http.post(
      Uri.parse('$baseUrl/auth/v1/signup'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': anonKey,
      },
      body: jsonEncode({
        'email': otherEmail,
        'password': 'TestPassword123!',
      }),
    );

    final otherData = jsonDecode(otherSignup.body);
    otherMerchantJwt = otherData['access_token'];
    final otherMerchantId = otherData['user']['id'];

    // Create test order in COURIER_ASSIGNED status
    final orderResponse = await http.post(
      Uri.parse('$baseUrl/rest/v1/orders'),
      headers: {
        'Content-Type': 'application/json',
        'apikey': anonKey,
        'Authorization': 'Bearer $merchantJwt',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'customer_id': merchantId,
        'merchant_id': merchantId,
        'status': 'COURIER_ASSIGNED',
        'delivery_price_user_set': 50,
        'prep_time_minutes': 20,
        'courier_id': merchantId,
        'items': [
          {'name': 'Test Item', 'quantity': 2, 'unit_price': 100}
        ],
      }),
    );

    final orderData = jsonDecode(orderResponse.body);
    testOrderId = orderData[0]['id'];
  });

  group('merchant_prep_ready RPC', () {
    test('TC-MER-PREP-READY-001: Successfully marks order as prep ready', () async {
      // Call RPC
      final response = await http.post(
        Uri.parse('$baseUrl/rest/v1/rpc/merchant_prep_ready'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
        },
        body: jsonEncode({
          'p_order_id': testOrderId,
        }),
      );

      expect(response.statusCode, equals(200));

      // Verify status changed to PICKED_UP
      final orderResponse = await http.get(
        Uri.parse('$baseUrl/rest/v1/orders?id=eq.$testOrderId&select=*'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
        },
      );

      final order = jsonDecode(orderResponse.body)[0];
      expect(order['status'], equals('PICKED_UP'));

      // Verify event was written
      final eventsResponse = await http.get(
        Uri.parse('$baseUrl/rest/v1/order_events?order_id=eq.$testOrderId&event_type=eq.MERCHANT_PREP_READY'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
        },
      );

      final events = jsonDecode(eventsResponse.body);
      expect(events.length, greaterThan(0));
      
      final event = events.last;
      expect(event['actor_type'], equals('MERCHANT'));
      expect(event['metadata']['ready_at'], isNotNull);
    });

    test('TC-MER-PREP-READY-002: RLS prevents other merchant from marking ready', () async {
      // Create order for other merchant
      final otherOrderResponse = await http.post(
        Uri.parse('$baseUrl/rest/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $otherMerchantJwt',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'customer_id': 'test-customer-id',
          'merchant_id': 'other-merchant-id',
          'status': 'COURIER_ASSIGNED',
          'delivery_price_user_set': 50,
          'prep_time_minutes': 15,
          'courier_id': 'test-courier-id',
          'items': [
            {'name': 'Other Item', 'quantity': 1, 'unit_price': 80}
          ],
        }),
      );

      final otherOrderData = jsonDecode(otherOrderResponse.body);
      final otherOrderId = otherOrderData[0]['id'];

      // Try to mark other merchant's order as ready (should fail)
      final response = await http.post(
        Uri.parse('$baseUrl/rest/v1/rpc/merchant_prep_ready'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
        },
        body: jsonEncode({
          'p_order_id': otherOrderId,
        }),
      );

      expect(response.statusCode, greaterThanOrEqualTo(400));
    });
  });

  group('merchant_extend_prep_time RPC', () {
    test('TC-MER-EXTEND-INT-001: +5 minutes extension succeeds', () async {
      // Create a fresh order
      final orderResponse = await http.post(
        Uri.parse('$baseUrl/rest/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'customer_id': 'test-customer',
          'merchant_id': 'test-merchant',
          'status': 'COURIER_ASSIGNED',
          'delivery_price_user_set': 50,
          'prep_time_minutes': 20,
          'courier_id': 'test-courier',
          'items': [
            {'name': 'Extend Test', 'quantity': 1, 'unit_price': 100}
          ],
        }),
      );

      final orderData = jsonDecode(orderResponse.body);
      final extendOrderId = orderData[0]['id'];

      // Call RPC
      final response = await http.post(
        Uri.parse('$baseUrl/rest/v1/rpc/merchant_extend_prep_time'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
        },
        body: jsonEncode({
          'p_order_id': extendOrderId,
          'p_plus_minutes': 5,
        }),
      );

      expect(response.statusCode, equals(200));

      // Verify prep time updated
      final orderCheckResponse = await http.get(
        Uri.parse('$baseUrl/rest/v1/orders?id=eq.$extendOrderId&select=prep_time_minutes'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
        },
      );

      final order = jsonDecode(orderCheckResponse.body)[0];
      expect(order['prep_time_minutes'], equals(25)); // 20 + 5

      // Verify event
      final eventsResponse = await http.get(
        Uri.parse('$baseUrl/rest/v1/order_events?order_id=eq.$extendOrderId&event_type=eq.MERCHANT_EXTEND_PREP'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
        },
      );

      final events = jsonDecode(eventsResponse.body);
      expect(events.length, greaterThan(0));

      final event = events.last;
      expect(event['metadata']['plus_minutes'], equals(5));
      expect(event['metadata']['new_prep_time'], equals(25));
    });

    test('TC-MER-EXTEND-INT-002: Upper bound enforced (max 90)', () async {
      // Create order with 85 minutes
      final orderResponse = await http.post(
        Uri.parse('$baseUrl/rest/v1/orders'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'customer_id': 'test-customer',
          'merchant_id': 'test-merchant',
          'status': 'COURIER_ASSIGNED',
          'delivery_price_user_set': 50,
          'prep_time_minutes': 85,
          'courier_id': 'test-courier',
          'items': [
            {'name': 'Max Test', 'quantity': 1, 'unit_price': 100}
          ],
        }),
      );

      final orderData = jsonDecode(orderResponse.body);
      final maxOrderId = orderData[0]['id'];

      // Try to add 10 (would be 95, should cap at 90)
      await http.post(
        Uri.parse('$baseUrl/rest/v1/rpc/merchant_extend_prep_time'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
        },
        body: jsonEncode({
          'p_order_id': maxOrderId,
          'p_plus_minutes': 10,
        }),
      );

      // Verify capped at 90
      final orderCheckResponse = await http.get(
        Uri.parse('$baseUrl/rest/v1/orders?id=eq.$maxOrderId&select=prep_time_minutes'),
        headers: {
          'apikey': anonKey,
          'Authorization': 'Bearer $merchantJwt',
        },
      );

      final order = jsonDecode(orderCheckResponse.body)[0];
      expect(order['prep_time_minutes'], equals(90));
    });
  });
}

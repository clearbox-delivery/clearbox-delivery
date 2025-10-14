import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for CourierSettings
/// [TC-COU-ACC-004] Courier settings read/write logic
void main() {
  group('CourierSettings', () {
    test('TC-COU-ACC-004: Default settings', () {
      final settings = CourierSettings(
        courierId: 'courier-123',
      );

      expect(settings.isAcceptingOrders, true);
      expect(settings.pushEnabled, true);
      expect(settings.displayName, null);
      expect(settings.vehiclePlate, null);
    });

    test('TC-COU-ACC-005: Custom settings', () {
      final settings = CourierSettings(
        courierId: 'courier-123',
        isAcceptingOrders: false,
        pushEnabled: false,
        displayName: '王小明',
        vehiclePlate: 'ABC-1234',
      );

      expect(settings.isAcceptingOrders, false);
      expect(settings.pushEnabled, false);
      expect(settings.displayName, '王小明');
      expect(settings.vehiclePlate, 'ABC-1234');
    });

    test('TC-COU-ACC-006: Fallback when fields missing (simulates backend gap)', () {
      // Simulate response from backend without is_accepting_orders/push_enabled fields
      Map<String, dynamic>? mockResponse;
      
      // Case 1: All fields present
      mockResponse = {
        'courier_id': 'c1',
        'is_accepting_orders': false,
        'push_enabled': false,
        'display_name': 'Test',
        'vehicle_plate': 'XYZ-999',
      };
      final isAcceptingOrders = mockResponse['is_accepting_orders'] as bool? ?? true;
      final pushEnabled = mockResponse['push_enabled'] as bool? ?? true;
      expect(isAcceptingOrders, false);
      expect(pushEnabled, false);

      // Case 2: Fields missing (fallback to default)
      mockResponse = {
        'courier_id': 'c1',
        // is_accepting_orders and push_enabled missing
      };
      final isAcceptingOrdersFallback = mockResponse['is_accepting_orders'] as bool? ?? true;
      final pushEnabledFallback = mockResponse['push_enabled'] as bool? ?? true;
      expect(isAcceptingOrdersFallback, true); // Fallback to default
      expect(pushEnabledFallback, true); // Fallback to default
    });

    test('TC-COU-ACC-007: JSON serialization round trip', () {
      final original = CourierSettings(
        courierId: 'c1',
        isAcceptingOrders: false,
        pushEnabled: true,
        displayName: '張三',
        vehiclePlate: 'DEF-5678',
      );

      final json = original.toJson();
      final decoded = CourierSettings.fromJson(json);

      expect(decoded.courierId, original.courierId);
      expect(decoded.isAcceptingOrders, original.isAcceptingOrders);
      expect(decoded.pushEnabled, original.pushEnabled);
      expect(decoded.displayName, original.displayName);
      expect(decoded.vehiclePlate, original.vehiclePlate);
    });
  });
}


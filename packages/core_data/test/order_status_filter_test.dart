import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for OrderStatus filtering
/// [TC-MER-CO-FILTER-001] Verify PICKED_UP status mapping and filtering
/// [merchant_app_whitepaper.md Section 4.4]
void main() {
  group('OrderStatus filtering', () {
    test('TC-MER-CO-FILTER-001: maps PICKED_UP to OrderStatus.pickedUp and filters correctly', () {
      final now = DateTime.now();
      final orders = [
        Order(
          id: 'o1',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.pickedUp,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o2',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.courierAssigned,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o3',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.delivered,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final pickedUp = orders.where((o) => o.status == OrderStatus.pickedUp).toList();
      
      expect(pickedUp.length, 1);
      expect(pickedUp.first.id, 'o1');
      expect(pickedUp.first.status, OrderStatus.pickedUp);
    });

    test('TC-MER-CO-FILTER-002: fromString correctly parses PICKED_UP', () {
      final status = OrderStatus.fromString('PICKED_UP');
      expect(status, OrderStatus.pickedUp);
      expect(status.value, 'PICKED_UP');
    });

    test('TC-MER-CO-FILTER-003: empty list when no picked-up orders', () {
      final now = DateTime.now();
      final orders = [
        Order(
          id: 'o1',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.courierAssigned,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final pickedUp = orders.where((o) => o.status == OrderStatus.pickedUp).toList();
      expect(pickedUp, isEmpty);
    });

    test('TC-MER-CO-FILTER-004: filters multiple picked-up orders', () {
      final now = DateTime.now();
      final orders = [
        Order(
          id: 'o1',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.pickedUp,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o2',
          customerId: 'c2',
          merchantId: 'm1',
          status: OrderStatus.pickedUp,
          deliveryPriceUserSet: 60.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o3',
          customerId: 'c3',
          merchantId: 'm1',
          status: OrderStatus.waitingCourier,
          deliveryPriceUserSet: 70.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final pickedUp = orders.where((o) => o.status == OrderStatus.pickedUp).toList();
      expect(pickedUp.length, 2);
      expect(pickedUp.map((o) => o.id), containsAll(['o1', 'o2']));
    });
  });
}


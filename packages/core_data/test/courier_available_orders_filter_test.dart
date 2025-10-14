import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for Courier available orders filtering
/// [TC-COU-FILTER-001] Available orders filtering (WAITING_COURIER only)
/// [courier_app_whitepaper.md Section 4.2]
void main() {
  group('Courier available orders filtering', () {
    final now = DateTime.now();

    test('TC-COU-FILTER-001: Filters only WAITING_COURIER orders', () {
      final orders = [
        Order(
          id: 'o1',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.waitingCourier,
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
          deliveryPriceUserSet: 60.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o3',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.waitingCourier,
          deliveryPriceUserSet: 70.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final available = orders
          .where((o) => o.status == OrderStatus.waitingCourier)
          .toList();

      expect(available.length, 2);
      expect(available.map((o) => o.id), containsAll(['o1', 'o3']));
    });

    test('TC-COU-FILTER-002: fromString parses WAITING_COURIER correctly', () {
      final status = OrderStatus.fromString('WAITING_COURIER');
      expect(status, OrderStatus.waitingCourier);
      expect(status.value, 'WAITING_COURIER');
    });

    test('TC-COU-FILTER-003: Empty list when no available orders', () {
      final orders = [
        Order(
          id: 'o1',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.delivered,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final available = orders
          .where((o) => o.status == OrderStatus.waitingCourier)
          .toList();

      expect(available, isEmpty);
    });

    test('TC-COU-FILTER-004: Simple delivery price sorting (descending)', () {
      final orders = [
        Order(
          id: 'o1',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.waitingCourier,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o2',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.waitingCourier,
          deliveryPriceUserSet: 80.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o3',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.waitingCourier,
          deliveryPriceUserSet: 65.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final sorted = List<Order>.from(orders)
        ..sort((a, b) => b.deliveryPriceUserSet.compareTo(a.deliveryPriceUserSet));

      expect(sorted[0].id, 'o2'); // 80
      expect(sorted[1].id, 'o3'); // 65
      expect(sorted[2].id, 'o1'); // 50
    });
  });
}


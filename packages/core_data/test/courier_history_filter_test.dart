import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for Courier History filtering
/// [TC-COU-HIS-001] History filters (status, time, search)
void main() {
  group('Courier History Filtering', () {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final lastWeek = now.subtract(const Duration(days: 7));

    final orders = [
      Order(
        id: 'order1',
        customerId: 'c1',
        merchantId: 'm1',
        courierId: 'courier1',
        status: OrderStatus.delivered,
        deliveryPriceUserSet: 50.0,
        items: const [],
        createdAt: yesterday,
        updatedAt: now,
      ),
      Order(
        id: 'order2',
        customerId: 'c2',
        merchantId: 'm2',
        courierId: 'courier1',
        status: OrderStatus.cancelledCustomer,
        deliveryPriceUserSet: 60.0,
        items: const [],
        createdAt: lastWeek,
        updatedAt: lastWeek,
      ),
      Order(
        id: 'order3',
        customerId: 'c3',
        merchantId: 'm3',
        courierId: 'courier1',
        status: OrderStatus.delivered,
        deliveryPriceUserSet: 70.0,
        items: const [],
        createdAt: yesterday,
        updatedAt: yesterday,
      ),
    ];

    test('TC-COU-HIS-001: Filter by DELIVERED status', () {
      final filtered = orders.where((o) => o.status == OrderStatus.delivered).toList();
      expect(filtered.length, 2);
      expect(filtered[0].id, 'order1');
      expect(filtered[1].id, 'order3');
    });

    test('TC-COU-HIS-002: Filter by cancelled status', () {
      final filtered = orders.where((o) =>
        o.status == OrderStatus.cancelledCustomer ||
        o.status == OrderStatus.cancelledMerchant ||
        o.status == OrderStatus.cancelledCourier
      ).toList();
      expect(filtered.length, 1);
      expect(filtered[0].id, 'order2');
    });

    test('TC-COU-HIS-003: Filter by time range (today)', () {
      final today = DateTime(now.year, now.month, now.day);
      final filtered = orders.where((o) =>
        o.updatedAt.isAfter(today) || o.updatedAt.isAtSameMomentAs(today)
      ).toList();
      expect(filtered.length, 1);
      expect(filtered[0].id, 'order1');
    });

    test('TC-COU-HIS-004: Search by order ID', () {
      final query = 'order1';
      final filtered = orders.where((o) => o.id.contains(query)).toList();
      expect(filtered.length, 1);
      expect(filtered[0].id, 'order1');
    });

    test('TC-COU-HIS-005: Combined filters (status + time)', () {
      final today = DateTime(now.year, now.month, now.day);
      final filtered = orders.where((o) =>
        o.status == OrderStatus.delivered &&
        (o.updatedAt.isAfter(today) || o.updatedAt.isAtSameMomentAs(today))
      ).toList();
      expect(filtered.length, 1);
      expect(filtered[0].id, 'order1'); // Only order1 updated today
    });
  });
}


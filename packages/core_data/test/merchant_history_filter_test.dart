import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for Merchant History filtering and time range
/// [TC-MER-HIS-FILTER-001] History filtering and time range logic
/// [merchant_app_whitepaper.md Section 5.1]
void main() {
  group('Merchant History filtering', () {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final lastWeek = now.subtract(const Duration(days: 8));
    final lastMonth = now.subtract(const Duration(days: 35));

    test('TC-MER-HIS-FILTER-001: Filters historical order statuses', () {
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
        Order(
          id: 'o2',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.cancelledMerchant,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o3',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.courierAssigned,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o4',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.expiredUnmatched,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final historicalStatuses = [
        OrderStatus.delivered,
        OrderStatus.cancelledMerchant,
        OrderStatus.cancelledCustomer,
        OrderStatus.cancelledCourier,
        OrderStatus.expiredUnmatched,
      ];

      final historical = orders
          .where((o) => historicalStatuses.contains(o.status))
          .toList();

      expect(historical.length, 3);
      expect(historical.map((o) => o.id), containsAll(['o1', 'o2', 'o4']));
    });

    test('TC-MER-HIS-FILTER-002: Time range today filters correctly', () {
      final todayStart = DateTime(now.year, now.month, now.day);
      
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
        Order(
          id: 'o2',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.delivered,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: yesterday,
          updatedAt: yesterday,
        ),
      ];

      final todayOrders = orders
          .where((o) => o.createdAt.isAfter(todayStart))
          .toList();

      expect(todayOrders.length, 1);
      expect(todayOrders.first.id, 'o1');
    });

    test('TC-MER-HIS-FILTER-003: Time range week filters correctly', () {
      final weekStart = now.subtract(const Duration(days: 7));
      
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
        Order(
          id: 'o2',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.delivered,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: lastWeek,
          updatedAt: lastWeek,
        ),
      ];

      final weekOrders = orders
          .where((o) => o.createdAt.isAfter(weekStart))
          .toList();

      expect(weekOrders.length, 1);
      expect(weekOrders.first.id, 'o1');
    });

    test('TC-MER-HIS-FILTER-004: Search by order ID partial match', () {
      final orders = [
        Order(
          id: 'abc123def456',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.delivered,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'xyz789uvw012',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.delivered,
          deliveryPriceUserSet: 50.0,
          items: const [],
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final searchResults = orders
          .where((o) => o.id.toLowerCase().contains('abc'))
          .toList();

      expect(searchResults.length, 1);
      expect(searchResults.first.id, 'abc123def456');
    });

    test('TC-MER-HIS-FILTER-005: Combined status and time range filtering', () {
      final todayStart = DateTime(now.year, now.month, now.day);
      
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
        Order(
          id: 'o2',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.cancelledMerchant,
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
          createdAt: yesterday,
          updatedAt: yesterday,
        ),
      ];

      final filtered = orders
          .where((o) => 
            o.status == OrderStatus.delivered &&
            o.createdAt.isAfter(todayStart))
          .toList();

      expect(filtered.length, 1);
      expect(filtered.first.id, 'o1');
    });
  });
}


import 'package:test/test.dart';
import 'package:domain/domain.dart';

/// Unit tests for courier order sorting
/// [TC-COU-SORT-001]
void main() {
  group('CourierPriorityCalculator', () {
    test('TC-COU-SORT-001: Orders sorted by R/T descending', () {
      // Order 1: R=50, T=10 → Priority=5.0
      final priority1 = CourierPriorityCalculator.calculatePriority(
        deliveryPrice: 50,
        travelTimeToMerchantMinutes: 5,
        prepTimeMinutes: 10,
        deliveryTimeMinutes: 5,
      );

      // Order 2: R=80, T=20 → Priority=4.0
      final priority2 = CourierPriorityCalculator.calculatePriority(
        deliveryPrice: 80,
        travelTimeToMerchantMinutes: 10,
        prepTimeMinutes: 15,
        deliveryTimeMinutes: 10,
      );

      // Order 1 should have higher priority
      expect(priority1, greaterThan(priority2));
      expect(priority1, closeTo(5.0, 0.5));
      expect(priority2, closeTo(4.0, 0.5));
    });

    test('Minimum time floor prevents division noise', () {
      // Very short times should be floored at 5 minutes
      final priority = CourierPriorityCalculator.calculatePriority(
        deliveryPrice: 50,
        travelTimeToMerchantMinutes: 1,
        prepTimeMinutes: 1,
        deliveryTimeMinutes: 1,
      );

      // Should use 5 min minimum
      expect(priority, closeTo(10.0, 0.1)); // 50 / 5 = 10
    });

    test('Higher delivery price increases priority', () {
      final lowPrice = CourierPriorityCalculator.calculatePriority(
        deliveryPrice: 30,
        travelTimeToMerchantMinutes: 10,
        prepTimeMinutes: 10,
        deliveryTimeMinutes: 10,
      );

      final highPrice = CourierPriorityCalculator.calculatePriority(
        deliveryPrice: 100,
        travelTimeToMerchantMinutes: 10,
        prepTimeMinutes: 10,
        deliveryTimeMinutes: 10,
      );

      expect(highPrice, greaterThan(lowPrice));
    });

    test('sortOrdersByPriority returns descending order', () {
      final orders = [
        OrderPriorityPair(
          orderId: 'order-1',
          priority: 3.0,
          deliveryPrice: 60,
          totalTimeMinutes: 20,
        ),
        OrderPriorityPair(
          orderId: 'order-2',
          priority: 5.0,
          deliveryPrice: 50,
          totalTimeMinutes: 10,
        ),
        OrderPriorityPair(
          orderId: 'order-3',
          priority: 4.0,
          deliveryPrice: 80,
          totalTimeMinutes: 20,
        ),
      ];

      final sorted = CourierPriorityCalculator.sortOrdersByPriority(orders);

      expect(sorted[0].orderId, equals('order-2')); // Priority 5.0
      expect(sorted[1].orderId, equals('order-3')); // Priority 4.0
      expect(sorted[2].orderId, equals('order-1')); // Priority 3.0
    });
  });
}



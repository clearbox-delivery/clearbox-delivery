import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for R/T calculator
/// [TC-COU-RT-001] R/T calculation and sorting
/// [courier_app_whitepaper.md Section 4.2]
void main() {
  group('R/T Calculator', () {
    final now = DateTime.now();

    test('TC-COU-RT-001: Basic R/T calculation', () {
      final order = Order(
        id: 'o1',
        customerId: 'c1',
        merchantId: 'm1',
        status: OrderStatus.waitingCourier,
        deliveryPriceUserSet: 60.0, // R = 60
        items: const [],
        prepTimeMinutes: 10,
        createdAt: now,
        updatedAt: now,
      );

      // courierToMerchant = 5, prepTime = 10, merchantToCustomer = 8
      // T = max(5, 10) + 8 = 18
      // R/T = 60 / 18 = 3.33...
      final rt = RTCalculator.calculateRT(
        order: order,
        courierToMerchantEta: 5,
        merchantToCustomerEta: 8,
      );

      expect(rt, closeTo(60.0 / 18.0, 0.01));
    });

    test('TC-COU-RT-002: Uses prepTime when larger than courierToMerchant', () {
      final order = Order(
        id: 'o1',
        customerId: 'c1',
        merchantId: 'm1',
        status: OrderStatus.waitingCourier,
        deliveryPriceUserSet: 80.0,
        items: const [],
        prepTimeMinutes: 20, // Larger
        createdAt: now,
        updatedAt: now,
      );

      // T = max(3, 20) + 5 = 25
      final rt = RTCalculator.calculateRT(
        order: order,
        courierToMerchantEta: 3,
        merchantToCustomerEta: 5,
      );

      expect(rt, closeTo(80.0 / 25.0, 0.01));
    });

    test('TC-COU-RT-003: Fallback values when ETAs missing', () {
      final order = Order(
        id: 'o1',
        customerId: 'c1',
        merchantId: 'm1',
        status: OrderStatus.waitingCourier,
        deliveryPriceUserSet: 50.0,
        items: const [],
        prepTimeMinutes: 15,
        createdAt: now,
        updatedAt: now,
      );

      // courierToMerchant = null → 5, merchantToCustomer = null → 5
      // T = max(5, 15) + 5 = 20
      final rt = RTCalculator.calculateRT(
        order: order,
        courierToMerchantEta: null,
        merchantToCustomerEta: null,
      );

      expect(rt, closeTo(50.0 / 20.0, 0.01));
    });

    test('TC-COU-RT-004: Fallback prepTime when missing', () {
      final order = Order(
        id: 'o1',
        customerId: 'c1',
        merchantId: 'm1',
        status: OrderStatus.waitingCourier,
        deliveryPriceUserSet: 60.0,
        items: const [],
        prepTimeMinutes: null, // Missing → 15
        createdAt: now,
        updatedAt: now,
      );

      // T = max(7, 15) + 6 = 21
      final rt = RTCalculator.calculateRT(
        order: order,
        courierToMerchantEta: 7,
        merchantToCustomerEta: 6,
      );

      expect(rt, closeTo(60.0 / 21.0, 0.01));
    });

    test('TC-COU-RT-005: Minimum T = 5 to avoid noise', () {
      final order = Order(
        id: 'o1',
        customerId: 'c1',
        merchantId: 'm1',
        status: OrderStatus.waitingCourier,
        deliveryPriceUserSet: 100.0,
        items: const [],
        prepTimeMinutes: 1,
        createdAt: now,
        updatedAt: now,
      );

      // T = max(1, 1) + 1 = 3 → clamped to 5
      final rt = RTCalculator.calculateRT(
        order: order,
        courierToMerchantEta: 1,
        merchantToCustomerEta: 1,
      );

      expect(rt, closeTo(100.0 / 5.0, 0.01)); // 20.0
    });

    test('TC-COU-RT-006: Sorting by R/T descending', () {
      final orders = [
        Order(
          id: 'o1',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.waitingCourier,
          deliveryPriceUserSet: 60.0, // R/T = 60/20 = 3.0
          items: const [],
          prepTimeMinutes: 15,
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o2',
          customerId: 'c1',
          merchantId: 'm2',
          status: OrderStatus.waitingCourier,
          deliveryPriceUserSet: 100.0, // R/T = 100/20 = 5.0 (highest)
          items: const [],
          prepTimeMinutes: 15,
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o3',
          customerId: 'c1',
          merchantId: 'm3',
          status: OrderStatus.waitingCourier,
          deliveryPriceUserSet: 80.0, // R/T = 80/20 = 4.0
          items: const [],
          prepTimeMinutes: 15,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final sorted = RTCalculator.sortByRT(
        orders: orders,
        courierToMerchantEtas: {},
        merchantToCustomerEtas: {},
      );

      expect(sorted[0].id, 'o2'); // R/T = 5.0
      expect(sorted[1].id, 'o3'); // R/T = 4.0
      expect(sorted[2].id, 'o1'); // R/T = 3.0
    });

    test('TC-COU-RT-007: Tie-breaker by deliveryPrice then createdAt', () {
      final earlier = now.subtract(const Duration(minutes: 5));

      final orders = [
        Order(
          id: 'o1',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.waitingCourier,
          deliveryPriceUserSet: 60.0, // Same R/T, same price, newer
          items: const [],
          prepTimeMinutes: 15,
          createdAt: now,
          updatedAt: now,
        ),
        Order(
          id: 'o2',
          customerId: 'c1',
          merchantId: 'm1',
          status: OrderStatus.waitingCourier,
          deliveryPriceUserSet: 60.0, // Same R/T, same price, older
          items: const [],
          prepTimeMinutes: 15,
          createdAt: earlier,
          updatedAt: earlier,
        ),
      ];

      final sorted = RTCalculator.sortByRT(
        orders: orders,
        courierToMerchantEtas: {},
        merchantToCustomerEtas: {},
      );

      // Tie-breaker: older first
      expect(sorted[0].id, 'o2');
      expect(sorted[1].id, 'o1');
    });
  });
}


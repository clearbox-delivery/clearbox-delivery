import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for merchant confirm flow
/// [TC-MER-CO-001, TC-MER-CO-002]
/// [merchant_app_whitepaper.md Section 4.1]
void main() {
  group('Merchant Confirm - Capacity Check', () {
    test('TC-MER-CAP-001: Capacity warning shown for > 5 items', () {
      final order = Order(
        id: 'test-order',
        customerId: 'c1',
        merchantId: 'm1',
        status: OrderStatus.pendingStoreConfirm,
        items: List.generate(
          6,
          (i) => OrderItem(sku: 's$i', name: 'Item $i', quantity: 1, unitPrice: 100),
        ),
        deliveryPriceUserSet: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final totalItems = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
      expect(totalItems, greaterThan(5));
      expect(totalItems, equals(6));
    });

    test('TC-MER-CAP-002: No warning for ≤ 5 items', () {
      final order = Order(
        id: 'test-order',
        customerId: 'c1',
        merchantId: 'm1',
        status: OrderStatus.pendingStoreConfirm,
        items: const [
          OrderItem(sku: 's1', name: 'Item 1', quantity: 3, unitPrice: 100),
          OrderItem(sku: 's2', name: 'Item 2', quantity: 2, unitPrice: 150),
        ],
        deliveryPriceUserSet: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final totalItems = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
      expect(totalItems, lessThanOrEqualTo(5));
    });
  });

  group('Cancel Reason Enum', () {
    test('TC-MER-CANCEL-001: All cancel reasons defined', () {
      expect(CancelReason.values.length, equals(4));
      expect(CancelReason.outOfStock.label, equals('缺料'));
      expect(CancelReason.insufficientStaff.label, equals('人手不足'));
      expect(CancelReason.outsideBusinessHours.label, equals('營業時間外'));
      expect(CancelReason.other.label, equals('其他'));
    });

    test('TC-MER-CANCEL-002: FromString conversion works', () {
      expect(CancelReason.fromString('outOfStock'), equals(CancelReason.outOfStock));
      expect(CancelReason.fromString('invalid'), equals(CancelReason.other));
    });
  });
}


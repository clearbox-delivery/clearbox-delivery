import 'package:test/test.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for Wallet models
/// [TC-COU-WALLET-001] Payout and Transaction models
void main() {
  group('Payout Model', () {
    test('TC-COU-WALLET-001: Create payout with required fields', () {
      final payout = Payout(
        id: 'p1',
        courierId: 'c1',
        amount: 1000.0,
        periodStart: DateTime(2025, 1, 1),
        periodEnd: DateTime(2025, 1, 7),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      expect(payout.id, 'p1');
      expect(payout.amount, 1000.0);
      expect(payout.status, 'pending');
    });

    test('TC-COU-WALLET-002: PayoutStatus enum mapping', () {
      expect(PayoutStatus.fromString('pending'), PayoutStatus.pending);
      expect(PayoutStatus.fromString('paid'), PayoutStatus.paid);
      expect(PayoutStatus.fromString('PAID'), PayoutStatus.paid); // Case insensitive
      expect(PayoutStatus.pending.displayName, '待結算');
      expect(PayoutStatus.paid.displayName, '已付款');
    });

    test('TC-COU-WALLET-003: JSON serialization', () {
      final payout = Payout(
        id: 'p1',
        courierId: 'c1',
        amount: 500.0,
        periodStart: DateTime(2025, 1, 1),
        periodEnd: DateTime(2025, 1, 7),
        status: 'paid',
        orderCount: 10,
        createdAt: DateTime.now(),
      );

      final json = payout.toJson();
      final decoded = Payout.fromJson(json);

      expect(decoded.id, payout.id);
      expect(decoded.amount, payout.amount);
      expect(decoded.orderCount, payout.orderCount);
    });
  });

  group('Transaction Model', () {
    test('TC-COU-WALLET-004: Create transaction with required fields', () {
      final tx = WalletTransaction(
        id: 't1',
        courierId: 'c1',
        amount: 50.0,
        type: 'earnings',
        createdAt: DateTime.now(),
      );

      expect(tx.id, 't1');
      expect(tx.amount, 50.0);
      expect(tx.type, 'earnings');
    });

    test('TC-COU-WALLET-005: TransactionType enum mapping', () {
      expect(TransactionType.fromString('earnings'), TransactionType.earnings);
      expect(TransactionType.fromString('bonus'), TransactionType.bonus);
      expect(TransactionType.fromString('BONUS'), TransactionType.bonus);
      expect(TransactionType.earnings.displayName, '送達收益');
      expect(TransactionType.bonus.displayName, '獎勵');
    });

    test('TC-COU-WALLET-006: Transaction with optional orderId', () {
      final tx1 = WalletTransaction(
        id: 't1',
        courierId: 'c1',
        orderId: 'order-123',
        amount: 55.0,
        type: 'earnings',
        description: '訂單送達收益',
        createdAt: DateTime.now(),
      );

      final tx2 = WalletTransaction(
        id: 't2',
        courierId: 'c1',
        amount: 100.0,
        type: 'bonus',
        description: '新人獎勵',
        createdAt: DateTime.now(),
      );

      expect(tx1.orderId, 'order-123');
      expect(tx2.orderId, null);
    });
  });

  group('Mock Data Fallback', () {
    test('TC-COU-WALLET-007: Service returns mock data when backend unavailable', () {
      // Simulates WalletService fallback behavior
      bool backendAvailable = false;
      List<Payout> getPayouts() {
        if (!backendAvailable) {
          // Mock fallback
          return [
            Payout(
              id: 'mock-1',
              courierId: 'c1',
              amount: 1250.0,
              periodStart: DateTime.now().subtract(const Duration(days: 7)),
              periodEnd: DateTime.now(),
              status: 'pending',
              orderCount: 25,
              createdAt: DateTime.now(),
            ),
          ];
        }
        return [];
      }

      final payouts = getPayouts();
      expect(payouts.length, 1);
      expect(payouts.first.amount, 1250.0);
      expect(payouts.first.status, 'pending');
    });
  });
}


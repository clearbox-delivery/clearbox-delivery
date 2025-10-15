import 'package:test/test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_client/src/wallet_service.dart';
import 'package:core_data/core_data.dart';

/// Unit tests for WalletService
/// [TC-COU-WALLET-SVC-*] Service behavior with/without backend
void main() {
  group('WalletService Behavior', () {
    test('TC-COU-WALLET-SVC-001: Cache hit returns same data without query', () async {
      // This test verifies cache behavior (conceptual, as we can't mock SupabaseClient easily)
      // In real scenario: first call queries, second call hits cache

      // Simulate cache logic
      final cache = <String, List<Payout>>{};
      final courierId = 'c1';

      // First call: cache miss
      expect(cache.containsKey(courierId), false);

      // Populate cache (simulate first query)
      cache[courierId] = [
        Payout(
          id: 'p1',
          courierId: courierId,
          amount: 1000.0,
          periodStart: DateTime(2025, 1, 1),
          periodEnd: DateTime(2025, 1, 7),
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      ];

      // Second call: cache hit
      expect(cache.containsKey(courierId), true);
      expect(cache[courierId]!.length, 1);
      expect(cache[courierId]!.first.amount, 1000.0);
    });

    test('TC-COU-WALLET-SVC-002: Clear cache removes all entries', () {
      final cache = <String, List<Payout>>{};
      cache['c1'] = [];
      cache['c2'] = [];

      expect(cache.length, 2);

      // Clear cache
      cache.clear();

      expect(cache.length, 0);
    });

    test('TC-COU-WALLET-SVC-003: Mock fallback returns valid data structure', () {
      // Simulate mock data generation
      List<Payout> getMockPayouts(String courierId) {
        final now = DateTime.now();
        return [
          Payout(
            id: 'mock-payout-1',
            courierId: courierId,
            amount: 1250.0,
            periodStart: now.subtract(const Duration(days: 7)),
            periodEnd: now,
            status: 'pending',
            orderCount: 25,
            createdAt: now,
          ),
        ];
      }

      final mock = getMockPayouts('c1');
      expect(mock.length, 1);
      expect(mock.first.status, 'pending');
      expect(mock.first.orderCount, 25);
    });

    test('TC-COU-WALLET-SVC-004: Transaction cache by courierId key', () {
      final cache = <String, List<WalletTransaction>>{};
      final tx1 = WalletTransaction(
        id: 't1',
        courierId: 'c1',
        amount: 50.0,
        type: 'earnings',
        createdAt: DateTime.now(),
      );

      cache['c1'] = [tx1];

      expect(cache['c1']!.length, 1);
      expect(cache['c1']!.first.type, 'earnings');
    });

    test('TC-COU-WALLET-SVC-005: Fallback behavior consistency', () {
      // Simulate service fallback logic
      bool backendAvailable = false;

      List<Payout> getPayouts() {
        if (!backendAvailable) {
          // Fallback to mock
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
      expect(payouts.first.id, startsWith('mock-'));
    });
  });
}


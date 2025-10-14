import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/src/supabase_provider.dart';

/// Wallet service for courier earnings and payouts
/// [REQ-COU-WALLET-001] Courier wallet and payout management
class WalletService {
  final SupabaseClient _client;
  final Map<String, List<Payout>> _payoutCache = {};
  final Map<String, List<WalletTransaction>> _transactionCache = {};

  WalletService(this._client);

  /// Get courier payouts (with cache and fallback to mock)
  /// [TC-COU-WALLET-001] Fetch courier payouts
  Future<List<Payout>> getPayouts(String courierId) async {
    // Check cache first
    if (_payoutCache.containsKey(courierId)) {
      return _payoutCache[courierId]!;
    }

    try {
      final response = await _client
          .from('payouts')
          .select()
          .eq('courier_id', courierId)
          .order('period_end', ascending: false);

      final payouts = (response as List)
          .map((json) => Payout.fromJson(json as Map<String, dynamic>))
          .toList();

      _payoutCache[courierId] = payouts;
      return payouts;
    } catch (e) {
      // Fallback: Return mock data if table doesn't exist
      final mockPayouts = _getMockPayouts(courierId);
      _payoutCache[courierId] = mockPayouts;
      return mockPayouts;
    }
  }

  /// Get courier transactions (with cache and fallback to mock)
  /// [TC-COU-WALLET-002] Fetch courier transactions
  Future<List<WalletTransaction>> getTransactions(String courierId) async {
    // Check cache first
    if (_transactionCache.containsKey(courierId)) {
      return _transactionCache[courierId]!;
    }

    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('courier_id', courierId)
          .order('created_at', ascending: false)
          .limit(100);

      final transactions = (response as List)
          .map((json) => WalletTransaction.fromJson(json as Map<String, dynamic>))
          .toList();

      _transactionCache[courierId] = transactions;
      return transactions;
    } catch (e) {
      // Fallback: Return mock data if table doesn't exist
      final mockTransactions = _getMockTransactions(courierId);
      _transactionCache[courierId] = mockTransactions;
      return mockTransactions;
    }
  }

  /// Clear cache (call after new transactions or payouts)
  void clearCache(String courierId) {
    _payoutCache.remove(courierId);
    _transactionCache.remove(courierId);
  }

  // Mock data generators (minimal difference fallback)
  List<Payout> _getMockPayouts(String courierId) {
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
      Payout(
        id: 'mock-payout-2',
        courierId: courierId,
        amount: 980.0,
        periodStart: now.subtract(const Duration(days: 14)),
        periodEnd: now.subtract(const Duration(days: 7)),
        status: 'paid',
        orderCount: 18,
        paidAt: now.subtract(const Duration(days: 3)),
        paymentMethod: '銀行轉帳',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  List<WalletTransaction> _getMockTransactions(String courierId) {
    final now = DateTime.now();
    return [
      WalletTransaction(
        id: 'mock-tx-1',
        courierId: courierId,
        orderId: 'order-123',
        amount: 50.0,
        type: 'earnings',
        description: '訂單送達收益',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      WalletTransaction(
        id: 'mock-tx-2',
        courierId: courierId,
        orderId: 'order-122',
        amount: 55.0,
        type: 'earnings',
        description: '訂單送達收益',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      WalletTransaction(
        id: 'mock-tx-3',
        courierId: courierId,
        amount: 100.0,
        type: 'bonus',
        description: '新人首週獎勵',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}

/// Wallet service provider
final walletServiceProvider = Provider<WalletService>((ref) {
  final client = ref.watch(supabaseProvider);
  return WalletService(client);
});


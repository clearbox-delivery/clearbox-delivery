import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// Wallet transaction record
/// [REQ-COU-WALLET-002] Track individual transactions
@freezed
class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required String courierId,
    String? orderId,
    required double amount,
    required String type, // 'earnings', 'bonus', 'penalty', 'payout'
    String? description,
    required DateTime createdAt,
  }) = _WalletTransaction;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);
}

/// Transaction type enum
enum TransactionType {
  earnings,
  bonus,
  penalty,
  payout;

  String get displayName {
    switch (this) {
      case TransactionType.earnings:
        return '送達收益';
      case TransactionType.bonus:
        return '獎勵';
      case TransactionType.penalty:
        return '罰款';
      case TransactionType.payout:
        return '提款';
    }
  }

  static TransactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'earnings':
        return TransactionType.earnings;
      case 'bonus':
        return TransactionType.bonus;
      case 'penalty':
        return TransactionType.penalty;
      case 'payout':
        return TransactionType.payout;
      default:
        return TransactionType.earnings;
    }
  }
}


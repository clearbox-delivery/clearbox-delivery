import 'package:freezed_annotation/freezed_annotation.dart';

part 'payout.freezed.dart';
part 'payout.g.dart';

/// Courier payout record
/// [REQ-COU-WALLET-001] Track courier earnings and payouts
@freezed
class Payout with _$Payout {
  const factory Payout({
    required String id,
    required String courierId,
    required double amount,
    required DateTime periodStart,
    required DateTime periodEnd,
    required String status, // 'pending', 'processing', 'paid', 'failed'
    int? orderCount,
    DateTime? paidAt,
    String? paymentMethod,
    String? notes,
    required DateTime createdAt,
  }) = _Payout;

  factory Payout.fromJson(Map<String, dynamic> json) =>
      _$PayoutFromJson(json);
}

/// Payout status enum
enum PayoutStatus {
  pending,
  processing,
  paid,
  failed;

  String get displayName {
    switch (this) {
      case PayoutStatus.pending:
        return '待結算';
      case PayoutStatus.processing:
        return '處理中';
      case PayoutStatus.paid:
        return '已付款';
      case PayoutStatus.failed:
        return '失敗';
    }
  }

  static PayoutStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PayoutStatus.pending;
      case 'processing':
        return PayoutStatus.processing;
      case 'paid':
        return PayoutStatus.paid;
      case 'failed':
        return PayoutStatus.failed;
      default:
        return PayoutStatus.pending;
    }
  }
}


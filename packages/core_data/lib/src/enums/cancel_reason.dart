/// Order cancellation reasons
/// [merchant_app_whitepaper.md Section 4.1]
enum CancelReason {
  outOfStock('缺料'),
  insufficientStaff('人手不足'),
  outsideBusinessHours('營業時間外'),
  other('其他');

  final String label;
  const CancelReason(this.label);

  static CancelReason fromString(String value) {
    return CancelReason.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CancelReason.other,
    );
  }
}


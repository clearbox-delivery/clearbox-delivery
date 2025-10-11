/// Actor type for audit trail
/// [REQ-CORE-AUDIT-001]
enum ActorType {
  customer('CUSTOMER'),
  merchant('MERCHANT'),
  courier('COURIER'),
  system('SYSTEM');

  const ActorType(this.value);
  final String value;

  static ActorType fromString(String value) {
    return ActorType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid actor type: $value'),
    );
  }
}



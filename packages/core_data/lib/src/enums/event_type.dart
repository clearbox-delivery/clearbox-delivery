/// Event types for order audit trail
/// [REQ-CORE-AUDIT-001]
enum EventType {
  orderCreated('ORDER_CREATED'),
  merchantConfirmed('MERCHANT_CONFIRMED'),
  courierAccepted('COURIER_ACCEPTED'),
  courierArrived('COURIER_ARRIVED'),
  orderPickedUp('ORDER_PICKED_UP'),
  orderDelivered('ORDER_DELIVERED'),
  orderCancelled('ORDER_CANCELLED'),
  prepTimeExtended('PREP_TIME_EXTENDED');

  const EventType(this.value);
  final String value;

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Invalid event type: $value'),
    );
  }
}



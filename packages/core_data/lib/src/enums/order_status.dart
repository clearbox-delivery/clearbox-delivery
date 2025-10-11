/// Order status enum aligned with database schema
/// See TEST_CASES.md for state machine transitions
enum OrderStatus {
  /// Customer created order, waiting for merchant to confirm stock/manufacturability
  /// [REQ-MER-CO-001]
  pendingStoreConfirm('PENDING_STORE_CONFIRM'),
  
  /// Merchant confirmed, waiting for courier to accept
  /// [REQ-COU-MATCH-003]
  waitingCourier('WAITING_COURIER'),
  
  /// Courier assigned and heading to merchant
  courierAssigned('COURIER_ASSIGNED'),
  
  /// Courier picked up order from merchant
  pickedUp('PICKED_UP'),
  
  /// Order being delivered to customer
  delivering('DELIVERING'),
  
  /// Order successfully delivered
  delivered('DELIVERED'),
  
  /// Cancelled by customer
  cancelledCustomer('CANCELLED_CUSTOMER'),
  
  /// Cancelled by merchant
  cancelledMerchant('CANCELLED_MERCHANT'),
  
  /// Cancelled by courier
  cancelledCourier('CANCELLED_COURIER'),
  
  /// System cancelled - no courier matched
  expiredUnmatched('EXPIRED_UNMATCHED');

  const OrderStatus(this.value);
  final String value;

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Invalid order status: $value'),
    );
  }
}



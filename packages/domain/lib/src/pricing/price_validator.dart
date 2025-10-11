/// Price validation logic
/// [REQ-CUST-ORDER-001] Customer sets delivery price with constraints
class PriceValidator {
  static const double minDeliveryPrice = 30.0;
  static const double maxDeliveryPrice = 5000.0;

  /// Validate delivery price
  /// Returns validation result
  /// [TC-CUST-001, TC-CUST-002]
  static PriceValidationResult validate(double price) {
    if (price < minDeliveryPrice) {
      return PriceValidationResult(
        isValid: false,
        errorCode: 'ERR_PRICE_MIN',
        message: 'Delivery price must be at least NT\$$minDeliveryPrice',
      );
    }

    if (price > maxDeliveryPrice) {
      return PriceValidationResult(
        isValid: false,
        errorCode: 'ERR_PRICE_MAX',
        message: 'Delivery price cannot exceed NT\$$maxDeliveryPrice',
      );
    }

    return PriceValidationResult(isValid: true);
  }
}

class PriceValidationResult {
  final bool isValid;
  final String? errorCode;
  final String? message;

  PriceValidationResult({
    required this.isValid,
    this.errorCode,
    this.message,
  });
}



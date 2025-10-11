import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Calculate courier order priority based on R/T formula
/// [REQ-COU-MATCH-003] Orders sorted by revenue/time ratio
/// [TC-COU-SORT-001]
class CourierPriorityCalculator {
  static const double minTimeMinutes = 5.0;

  /// Calculate priority score for order
  /// R = delivery_price_user_set
  /// T = max(travel_time_to_merchant, prep_time) + delivery_time
  /// Priority = R / max(T, 5) to avoid noise from very short times
  static double calculatePriority({
    required double deliveryPrice,
    required double travelTimeToMerchantMinutes,
    required double prepTimeMinutes,
    required double deliveryTimeMinutes,
  }) {
    final R = deliveryPrice;
    final T = max(travelTimeToMerchantMinutes, prepTimeMinutes) + 
              deliveryTimeMinutes;
    
    // Minimum 5 minutes to avoid division noise
    final effectiveTime = max(T, minTimeMinutes);
    
    return R / effectiveTime;
  }

  /// Sort orders by priority (descending - highest priority first)
  static List<OrderPriorityPair> sortOrdersByPriority(
    List<OrderPriorityPair> orders,
  ) {
    final sorted = List<OrderPriorityPair>.from(orders);
    sorted.sort((a, b) => b.priority.compareTo(a.priority));
    return sorted;
  }
}

class OrderPriorityPair {
  final String orderId;
  final double priority;
  final double deliveryPrice;
  final double totalTimeMinutes;

  OrderPriorityPair({
    required this.orderId,
    required this.priority,
    required this.deliveryPrice,
    required this.totalTimeMinutes,
  });
}



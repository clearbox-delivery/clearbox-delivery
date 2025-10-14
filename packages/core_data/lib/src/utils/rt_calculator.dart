import 'package:core_data/core_data.dart';

/// R/T (Revenue per Time) calculator for courier order sorting
/// [courier_app_whitepaper.md Section 4.2]
/// [REQ-COU-FLOW-002] Calculate R/T = deliveryPrice / totalTimeMinutes
class RTCalculator {
  /// Calculate R/T score for an order
  /// 
  /// R = deliveryPriceUserSet
  /// T = max(courierToMerchantEta, prepTimeMinutes) + merchantToCustomerEta
  /// 
  /// Fallbacks:
  /// - courierToMerchantEta missing → 5 min
  /// - merchantToCustomerEta missing → 5 min
  /// - prepTimeMinutes missing → 15 min
  /// - Minimum T = 5 min (avoid division noise)
  static double calculateRT({
    required Order order,
    int? courierToMerchantEta,
    int? merchantToCustomerEta,
  }) {
    final R = order.deliveryPriceUserSet;
    
    final courierToMerchant = courierToMerchantEta ?? 5;
    final prepTime = order.prepTimeMinutes ?? 15;
    final merchantToCustomer = merchantToCustomerEta ?? 5;
    
    // T = max(courierToMerchant, prepTime) + merchantToCustomer
    final maxWait = courierToMerchant > prepTime ? courierToMerchant : prepTime;
    var T = maxWait + merchantToCustomer;
    
    // Minimum 5 minutes to avoid noise
    if (T < 5) T = 5;
    
    return R / T;
  }

  /// Sort orders by R/T (descending), with tie-breakers
  /// 1. R/T descending
  /// 2. deliveryPrice descending
  /// 3. createdAt ascending (older first)
  static List<Order> sortByRT({
    required List<Order> orders,
    required Map<String, int?> courierToMerchantEtas,
    required Map<String, int?> merchantToCustomerEtas,
  }) {
    final ordersWithRT = orders.map((order) {
      final rt = calculateRT(
        order: order,
        courierToMerchantEta: courierToMerchantEtas[order.merchantId],
        merchantToCustomerEta: merchantToCustomerEtas[order.id],
      );
      return _OrderWithRT(order: order, rt: rt);
    }).toList();

    ordersWithRT.sort((a, b) {
      // 1. R/T descending
      final rtCompare = b.rt.compareTo(a.rt);
      if (rtCompare != 0) return rtCompare;

      // 2. Delivery price descending
      final priceCompare = b.order.deliveryPriceUserSet
          .compareTo(a.order.deliveryPriceUserSet);
      if (priceCompare != 0) return priceCompare;

      // 3. Created time ascending (older first)
      return a.order.createdAt.compareTo(b.order.createdAt);
    });

    return ordersWithRT.map((e) => e.order).toList();
  }
}

class _OrderWithRT {
  final Order order;
  final double rt;

  _OrderWithRT({required this.order, required this.rt});
}


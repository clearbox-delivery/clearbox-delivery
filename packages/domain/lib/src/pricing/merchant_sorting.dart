import 'dart:math';
import 'package:geo_h3/geo_h3.dart';
import 'package:latlong2/latlong.dart';

/// Merchant sorting score calculation
/// [REQ-CUST-SORT-001] S = 0.5 * D + 0.5 * R
/// D = exp(-d / λ) distance score
/// R = normalized meal count score (P95 capped, min-max normalized)
class MerchantSortingCalculator {
  static const double lambda = 1500.0; // meters
  static const double distanceWeight = 0.5;
  static const double mealCountWeight = 0.5;

  /// Calculate composite sorting score
  static double calculateScore({
    required LatLng customerLocation,
    required LatLng merchantLocation,
    required int weeklyMealCount,
    required int maxMealCount,
    required int minMealCount,
  }) {
    // Distance score: D = exp(-d / λ)
    final d = DistanceCalculator.calculateDistance(
      customerLocation,
      merchantLocation,
    );
    final D = exp(-d / lambda);

    // Meal count score: min-max normalized
    final R = _normalizeM ealCount(
      weeklyMealCount,
      minMealCount,
      maxMealCount,
    );

    // Composite: S = 0.5 * D + 0.5 * R
    return distanceWeight * D + mealCountWeight * R;
  }

  /// Min-max normalize meal count (0 to 1)
  static double _normalizeMealCount(int count, int min, int max) {
    if (max == min) return 0.5;
    return (count - min) / (max - min);
  }

  /// Calculate P95 percentile for meal counts (cap extreme values)
  static int calculateP95(List<int> mealCounts) {
    if (mealCounts.isEmpty) return 0;
    
    final sorted = List<int>.from(mealCounts)..sort();
    final index = (sorted.length * 0.95).floor();
    return sorted[min(index, sorted.length - 1)];
  }
}



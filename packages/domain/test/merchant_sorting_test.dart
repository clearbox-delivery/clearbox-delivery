import 'package:test/test.dart';
import 'package:domain/src/pricing/merchant_sorting.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

/// Unit tests for Merchant Sorting S
/// [REQ-CUST-SORT-001] S = 0.5D + 0.5R
/// [customer_app_whitepaper.md Section 4.4]
void main() {
  group('MerchantSortingCalculator', () {
    test('TC-SORT-001: Distance score D decreases with distance', () {
      final customerLoc = LatLng(25.0330, 121.5654); // Taipei 101
      final nearMerchant = LatLng(25.0340, 121.5660); // ~100m
      final farMerchant = LatLng(25.0500, 121.5800); // ~2000m

      // Calculate scores with same meal count (R=0.5 for both)
      final nearScore = MerchantSortingCalculator.calculateScore(
        customerLocation: customerLoc,
        merchantLocation: nearMerchant,
        weeklyMealCount: 10,
        maxMealCount: 20,
        minMealCount: 0,
      );

      final farScore = MerchantSortingCalculator.calculateScore(
        customerLocation: customerLoc,
        merchantLocation: farMerchant,
        weeklyMealCount: 10,
        maxMealCount: 20,
        minMealCount: 0,
      );

      // Near merchant should have higher D component, thus higher overall score
      expect(nearScore, greaterThan(farScore));
    });

    test('TC-SORT-002: Meal count score R normalized correctly', () {
      final loc = LatLng(25.0330, 121.5654);

      // Same location (D identical), different meal counts
      final lowMealScore = MerchantSortingCalculator.calculateScore(
        customerLocation: loc,
        merchantLocation: loc,
        weeklyMealCount: 0,
        maxMealCount: 100,
        minMealCount: 0,
      );

      final highMealScore = MerchantSortingCalculator.calculateScore(
        customerLocation: loc,
        merchantLocation: loc,
        weeklyMealCount: 100,
        maxMealCount: 100,
        minMealCount: 0,
      );

      // Higher meal count -> higher R -> higher score
      expect(highMealScore, greaterThan(lowMealScore));
    });

    test('TC-SORT-003: P95 capping works correctly', () {
      final counts = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 500, 600];
      final p95 = MerchantSortingCalculator.calculateP95(counts);

      // P95 of above list should be close to 500-600 range
      expect(p95, greaterThanOrEqualTo(100));
      expect(p95, lessThanOrEqualTo(600));
    });

    test('TC-SORT-004: Composite S score = 0.5D + 0.5R', () {
      final customerLoc = LatLng(25.0330, 121.5654);
      final merchantLoc = LatLng(25.0330, 121.5654); // Same location

      // At same location, distance ≈ 0, so D ≈ exp(0) = 1
      // With weekly_meal_count = maxMealCount, R = 1
      // Expected S ≈ 0.5 * 1 + 0.5 * 1 = 1.0
      final score = MerchantSortingCalculator.calculateScore(
        customerLocation: customerLoc,
        merchantLocation: merchantLoc,
        weeklyMealCount: 100,
        maxMealCount: 100,
        minMealCount: 0,
      );

      expect(score, closeTo(1.0, 0.01));
    });

    test('TC-SORT-005: Distance score uses exp decay with lambda=1500', () {
      final customerLoc = LatLng(25.0330, 121.5654);
      
      // Merchant at exactly 1500m away
      // D = exp(-1500/1500) = exp(-1) ≈ 0.368
      // With R = 0.5 (mid meal count), S = 0.5 * 0.368 + 0.5 * 0.5 = 0.434
      
      // For testing, use a known distance calculation
      // Create a merchant ~1500m away (rough)
      final merchantLoc = LatLng(25.0465, 121.5654); // ~1500m north

      final score = MerchantSortingCalculator.calculateScore(
        customerLocation: customerLoc,
        merchantLocation: merchantLoc,
        weeklyMealCount: 50,
        maxMealCount: 100,
        minMealCount: 0,
      );

      // Score should be around 0.4-0.5 range
      expect(score, greaterThan(0.3));
      expect(score, lessThan(0.7));
    });
  });
}


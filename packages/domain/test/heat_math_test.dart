import 'package:test/test.dart';
import 'package:domain/domain.dart';

/// Unit tests for Heat Map calculations
/// [TC-COU-HEAT-001] Heat score calculation and normalization
/// [courier_app_whitepaper.md Section 4.1]
void main() {
  group('HeatMath', () {
    test('TC-COU-HEAT-001: Basic heat score S = waiting / (active + 1)', () {
      expect(HeatMath.computeHeatScore(waitingOrders: 10, activeCouriers: 4), 2.0);
      expect(HeatMath.computeHeatScore(waitingOrders: 5, activeCouriers: 0), 5.0);
      expect(HeatMath.computeHeatScore(waitingOrders: 0, activeCouriers: 2), 0.0);
    });

    test('TC-COU-HEAT-002: Normalize with P10/P90', () {
      // value between p10 and p90
      expect(HeatMath.normalize(value: 5.0, p10: 0.0, p90: 10.0), closeTo(0.5, 0.01));

      // value below p10
      expect(HeatMath.normalize(value: -5.0, p10: 0.0, p90: 10.0), 0.0);

      // value above p90
      expect(HeatMath.normalize(value: 15.0, p10: 0.0, p90: 10.0), 1.0);

      // edge case: p10 == p90
      expect(HeatMath.normalize(value: 5.0, p10: 5.0, p90: 5.0), 0.5);
    });

    test('TC-COU-HEAT-003: Apply gamma curve (1/gamma exponent)', () {
      // gamma = 1.4, x = 0.5
      // x' = 0.5^(1/1.4) ≈ 0.609
      final result = HeatMath.applyGamma(0.5, gamma: 1.4);
      expect(result, greaterThan(0.5)); // Boosts mid-range
      expect(result, closeTo(0.609, 0.01));

      // Monotonic: higher input → higher output
      expect(HeatMath.applyGamma(0.3, gamma: 1.4), lessThan(HeatMath.applyGamma(0.7, gamma: 1.4)));

      // Edge cases
      expect(HeatMath.applyGamma(0.0), 0.0);
      expect(HeatMath.applyGamma(1.0), 1.0);
    });

    test('TC-COU-HEAT-004: EMA smoothing', () {
      // H_t = 0.2 * 0.8 + 0.8 * 0.5 = 0.56
      expect(HeatMath.ema(previous: 0.5, current: 0.8, alpha: 0.2), closeTo(0.56, 0.01));

      // No previous (use current)
      expect(HeatMath.ema(previous: 0.0, current: 0.8, alpha: 0.2), closeTo(0.16, 0.01));

      // Alpha edge cases
      expect(() => HeatMath.ema(previous: 0.5, current: 0.8, alpha: -0.1), throwsArgumentError);
      expect(() => HeatMath.ema(previous: 0.5, current: 0.8, alpha: 1.5), throwsArgumentError);
    });

    test('TC-COU-HEAT-005: Compute P10/P90 percentiles', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0];
      final (p10, p90) = HeatMath.computePercentiles(values);

      // P10 = index 1 → 2.0, P90 = index 9 → 10.0
      expect(p10, closeTo(2.0, 0.1));
      expect(p90, closeTo(10.0, 0.1));

      // Empty list
      final (p10Empty, p90Empty) = HeatMath.computePercentiles([]);
      expect(p10Empty, 0.0);
      expect(p90Empty, 0.0);

      // Single value
      final (p10Single, p90Single) = HeatMath.computePercentiles([5.0]);
      expect(p10Single, 5.0);
      expect(p90Single, 5.0);
    });

    test('TC-COU-HEAT-006: Full pipeline without EMA', () {
      // S = 10 / (2+1) = 3.333
      // Normalize with p10=0, p90=10: x = 3.333/10 = 0.3333
      // Gamma 1.4: x' = 0.3333^(1/1.4) ≈ 0.445
      final heat = HeatMath.computeFinalHeat(
        waitingOrders: 10,
        activeCouriers: 2,
        p10: 0.0,
        p90: 10.0,
        previousHeat: null,
        gamma: 1.4,
        alpha: 0.2,
      );

      expect(heat, greaterThan(0.3)); // Gamma boost
      expect(heat, lessThan(0.5));
      expect(heat, closeTo(0.445, 0.02));
    });

    test('TC-COU-HEAT-007: Full pipeline with EMA', () {
      // Current: same as TC-006 ≈ 0.445
      // Previous: 0.3
      // EMA: 0.2 * 0.445 + 0.8 * 0.3 = 0.329
      final heat = HeatMath.computeFinalHeat(
        waitingOrders: 10,
        activeCouriers: 2,
        p10: 0.0,
        p90: 10.0,
        previousHeat: 0.3,
        gamma: 1.4,
        alpha: 0.2,
      );

      expect(heat, closeTo(0.329, 0.02));
    });
  });
}


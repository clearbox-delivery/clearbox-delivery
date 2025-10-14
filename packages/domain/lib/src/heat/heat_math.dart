import 'dart:math' as math;

/// Heat map calculation for courier demand visualization
/// [courier_app_whitepaper.md Section 4.1]
/// [REQ-COU-HEAT-001] Calculate and normalize heat scores
class HeatMath {
  /// Compute raw heat score S
  /// S = waitingOrders / (activeCouriers + 1)
  ///
  /// [courier_app_whitepaper.md Section 4.1]
  static double computeHeatScore({
    required int waitingOrders,
    required int activeCouriers,
  }) {
    return waitingOrders / (activeCouriers + 1);
  }

  /// Normalize value using P10/P90 percentiles
  /// x = clamp((value - p10) / (p90 - p10), 0, 1)
  ///
  /// Handles edge cases:
  /// - If p90 == p10, returns 0.5
  /// - Clamps result to [0, 1]
  static double normalize({
    required double value,
    required double p10,
    required double p90,
  }) {
    if (p90 == p10) return 0.5;

    final normalized = (value - p10) / (p90 - p10);
    return normalized.clamp(0.0, 1.0);
  }

  /// Apply gamma curve for better visual distribution
  /// x' = x^(1/gamma)
  ///
  /// Common gamma values: 1.2 - 1.6 (default 1.4)
  /// Higher gamma = more contrast in mid-range
  static double applyGamma(double x, {double gamma = 1.4}) {
    if (gamma <= 0) throw ArgumentError('Gamma must be positive');
    return math.pow(x, 1.0 / gamma).toDouble();
  }

  /// Exponential moving average for temporal smoothing
  /// H_t = α * x'_t + (1-α) * H_{t-1}
  ///
  /// Typical alpha: 0.2 (half-life ~2-3 minutes with 30s updates)
  static double ema({
    required double previous,
    required double current,
    double alpha = 0.2,
  }) {
    if (alpha < 0 || alpha > 1) {
      throw ArgumentError('Alpha must be in [0, 1]');
    }
    return alpha * current + (1 - alpha) * previous;
  }

  /// Compute P10 and P90 percentiles from a list of values
  /// Returns (p10, p90)
  static (double, double) computePercentiles(List<double> values) {
    if (values.isEmpty) return (0.0, 0.0);
    if (values.length == 1) return (values.first, values.first);

    final sorted = List<double>.from(values)..sort();

    final p10Index = (sorted.length * 0.1).floor();
    final p90Index = (sorted.length * 0.9).floor();

    return (sorted[p10Index], sorted[p90Index]);
  }

  /// Full heat pipeline: S → normalize → gamma → EMA
  ///
  /// Returns final heat value in [0, 1] ready for color mapping
  static double computeFinalHeat({
    required int waitingOrders,
    required int activeCouriers,
    required double p10,
    required double p90,
    double? previousHeat,
    double gamma = 1.4,
    double alpha = 0.2,
  }) {
    // Step 1: Compute S
    final s = computeHeatScore(
      waitingOrders: waitingOrders,
      activeCouriers: activeCouriers,
    );

    // Step 2: Normalize
    final normalized = normalize(value: s, p10: p10, p90: p90);

    // Step 3: Apply gamma
    final gammaAdjusted = applyGamma(normalized, gamma: gamma);

    // Step 4: EMA (if previous available)
    if (previousHeat != null) {
      return ema(previous: previousHeat, current: gammaAdjusted, alpha: alpha);
    }

    return gammaAdjusted;
  }
}


import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// Calculate distances between coordinates
class DistanceCalculator {
  static const Distance _distance = Distance();

  /// Calculate straight-line distance in meters
  static double calculateDistance(LatLng from, LatLng to) {
    return _distance.as(LengthUnit.Meter, from, to);
  }

  /// Exponential decay distance score for sorting
  /// Used in customer app store sorting [REQ-CUST-SORT-001]
  /// D = exp(-d / λ) where d is distance in meters, λ default 1500
  static double exponentialDecayScore(
    LatLng from,
    LatLng to, {
    double lambda = 1500.0,
  }) {
    final d = calculateDistance(from, to);
    return math.exp(-d / lambda);
  }
}



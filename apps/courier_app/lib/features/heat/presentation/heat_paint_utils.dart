import 'dart:ui';

/// Utilities for heat map painting and visualization
/// [REQ-COU-HEAT-002] Heat map rendering utilities
class HeatPaintUtils {
  /// Map heat value [0, 1] to color gradient
  /// White (0) → Yellow (0.33) → Orange (0.66) → Red (1)
  ///
  /// Uses linear interpolation between color stops
  static Color heatToColor(double heat) {
    heat = heat.clamp(0.0, 1.0);

    // Color stops
    const white = Color(0xFFFFFFFF);
    const yellow = Color(0xFFFFEB3B); // Material Yellow 500
    const orange = Color(0xFFFF9800); // Material Orange 500
    const red = Color(0xFFF44336); // Material Red 500

    if (heat < 0.33) {
      // White → Yellow
      final t = heat / 0.33;
      return Color.lerp(white, yellow, t)!;
    } else if (heat < 0.66) {
      // Yellow → Orange
      final t = (heat - 0.33) / 0.33;
      return Color.lerp(yellow, orange, t)!;
    } else {
      // Orange → Red
      final t = (heat - 0.66) / 0.34;
      return Color.lerp(orange, red, t)!;
    }
  }

  /// Convert H3 cell offset (relative to center) to canvas coordinates
  /// Assumes hexagonal grid with flat-top orientation
  ///
  /// Returns (dx, dy) where (0, 0) is canvas center
  ///
  /// Hexagon layout (flat-top):
  /// - Horizontal spacing: 1.5 * size
  /// - Vertical spacing: sqrt(3) * size
  /// - Offset rows stagger by 0.5 horizontally
  static Offset h3OffsetToCanvas({
    required int q, // Column (horizontal)
    required int r, // Row (vertical)
    required double cellSize,
  }) {
    final sqrt3 = 1.732050808; // sqrt(3)

    // Flat-top hexagon layout
    final x = cellSize * 1.5 * q;
    final y = cellSize * sqrt3 * (r + q / 2.0);

    return Offset(x, y);
  }

  /// Generate k-ring (all cells within distance k from center)
  /// Returns list of (q, r) axial coordinates
  ///
  /// For k=40, this generates ~4921 cells
  /// Uses cube coordinate system for proper hexagonal distance
  static List<(int, int)> generateKRing(int k) {
    final cells = <(int, int)>[];

    for (int q = -k; q <= k; q++) {
      final r1 = (-k - q).clamp(-k, k);
      final r2 = (k - q).clamp(-k, k);

      for (int r = r1; r <= r2; r++) {
        cells.add((q, r));
      }
    }

    return cells;
  }

  /// Check if point is inside hexagon
  /// Used for tap hit testing
  ///
  /// Hexagon vertices (flat-top):
  /// - 6 vertices at angles: 0°, 60°, 120°, 180°, 240°, 300°
  static bool isPointInHexagon({
    required Offset point,
    required Offset hexCenter,
    required double size,
  }) {
    final dx = point.dx - hexCenter.dx;
    final dy = point.dy - hexCenter.dy;

    // Fast bounding box check first
    final sqrt3 = 1.732050808;
    if (dx.abs() > size * 1.5 || dy.abs() > size * sqrt3) {
      return false;
    }

    // Hexagon contains point if distance from center to all 6 edges is positive
    // For flat-top hexagon, use simplified check
    final q = (2.0 / 3.0 * dx) / size;
    final r = (-1.0 / 3.0 * dx + sqrt3 / 3.0 * dy) / size;
    final s = -q - r;

    // Check if within unit hexagon
    return q.abs() < 1 && r.abs() < 1 && s.abs() < 1;
  }

  /// Convert canvas point to hexagonal axial coordinates (q, r)
  /// Inverse of h3OffsetToCanvas
  static (int, int) canvasToH3Offset({
    required Offset point,
    required double cellSize,
  }) {
    final sqrt3 = 1.732050808;

    // Inverse transformation
    final q = (2.0 / 3.0 * point.dx) / cellSize;
    final r = (-1.0 / 3.0 * point.dx + sqrt3 / 3.0 * point.dy) / cellSize;

    // Round to nearest integer hex coordinate
    return _roundHex(q, r);
  }

  /// Round fractional hex coordinates to nearest integer hex
  /// Uses cube coordinate system for proper rounding
  static (int, int) _roundHex(double q, double r) {
    final s = -q - r;

    var rq = q.round();
    var rr = r.round();
    var rs = s.round();

    final qDiff = (rq - q).abs();
    final rDiff = (rr - r).abs();
    final sDiff = (rs - s).abs();

    if (qDiff > rDiff && qDiff > sDiff) {
      rq = -rr - rs;
    } else if (rDiff > sDiff) {
      rr = -rq - rs;
    }

    return (rq, rr);
  }
}


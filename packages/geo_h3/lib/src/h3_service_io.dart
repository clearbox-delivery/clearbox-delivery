import 'package:latlong2/latlong.dart';

/// H3 geospatial service (IO platforms)
/// Using simplified grid for dev/MVP compatibility
/// TODO Phase 4+: integrate real H3 BigInt bindings for mobile production
class H3Service {
  static const int resolution = 10;
  static const int kRingDistance = 40;

  static String toH3Res10(LatLng coord) {
    final qLat = (coord.latitude * 1000).floor();
    final qLon = (coord.longitude * 1000).floor();
    return '$qLat:$qLon';
  }

  static Set<String> kRing(String cell, int k) {
    final parts = cell.split(':');
    final baseLat = int.parse(parts[0]);
    final baseLon = int.parse(parts[1]);
    final Set<String> out = {};
    for (int dy = -k; dy <= k; dy++) {
      for (int dx = -k; dx <= k; dx++) {
        out.add('${baseLat + dy}:${baseLon + dx}');
      }
    }
    return out;
  }

  static Set<String> getVisibilityRing(String centerCell) {
    return kRing(centerCell, kRingDistance);
  }

  static bool isWithinDistance(String cell1, String cell2, int k) {
    return gridDistance(cell1, cell2) <= k;
  }

  static int gridDistance(String cell1, String cell2) {
    final a = cell1.split(':').map(int.parse).toList();
    final b = cell2.split(':').map(int.parse).toList();
    return (a[0] - b[0]).abs() + (a[1] - b[1]).abs();
  }

  static LatLng h3ToLatLng(String cell) {
    final parts = cell.split(':');
    final lat = int.parse(parts[0]) / 1000.0;
    final lon = int.parse(parts[1]) / 1000.0;
    return LatLng(lat, lon);
  }
}



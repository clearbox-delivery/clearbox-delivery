import 'package:h3_dart/h3_dart.dart';
import 'package:latlong2/latlong.dart';

/// H3 geospatial service
/// Resolution 10 used throughout the system for merchant/customer locations
/// k=40 ring for visibility/matching radius
class H3Service {
  static const int resolution = 10;
  static const int kRingDistance = 40;

  /// Convert lat/lng to H3 cell at resolution 10
  /// [TC-GEO-H3-001]
  static String toH3Res10(LatLng coord) {
    final h3 = H3Factory.instance;
    return h3.geoToH3(
      GeoCoord(lat: coord.latitude, lon: coord.longitude),
      resolution,
    );
  }

  /// Get k-ring (neighbors within distance k) for a cell
  /// [TC-GEO-H3-001]
  static Set<String> kRing(String cell, int k) {
    final h3 = H3Factory.instance;
    return h3.kRing(cell, k).toSet();
  }

  /// Get k=40 ring for merchant visibility radius
  static Set<String> getVisibilityRing(String centerCell) {
    return kRing(centerCell, kRingDistance);
  }

  /// Check if two cells are within k distance
  static bool isWithinDistance(String cell1, String cell2, int k) {
    final ring = kRing(cell1, k);
    return ring.contains(cell2);
  }

  /// Get distance between two H3 cells (in grid steps)
  static int gridDistance(String cell1, String cell2) {
    final h3 = H3Factory.instance;
    return h3.h3Distance(cell1, cell2);
  }

  /// Convert H3 cell back to lat/lng (center point)
  static LatLng h3ToLatLng(String cell) {
    final h3 = H3Factory.instance;
    final geo = h3.h3ToGeo(cell);
    return LatLng(geo.lat, geo.lon);
  }
}



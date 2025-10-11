import 'package:test/test.dart';
import 'package:geo_h3/geo_h3.dart';
import 'package:latlong2/latlong.dart';

/// Unit tests for H3 geospatial functions
/// [TC-GEO-H3-001]
void main() {
  group('H3Service', () {
    test('TC-GEO-H3-001: H3 res=10 conversion', () {
      // Taipei 101 coordinates
      final coord = LatLng(25.0340, 121.5645);
      final cell = H3Service.toH3Res10(coord);
      
      // Should return valid H3 cell string
      expect(cell, isNotEmpty);
      expect(cell.length, greaterThan(10));
    });

    test('TC-GEO-H3-001: k=40 ring calculation', () {
      final coord = LatLng(25.0340, 121.5645);
      final cell = H3Service.toH3Res10(coord);
      final ring = H3Service.kRing(cell, 40);
      
      // k=40 ring should contain many cells
      expect(ring.length, greaterThan(1));
      expect(ring.contains(cell), isTrue); // Should include center
    });

    test('Visibility ring returns k=40', () {
      final cell = H3Service.toH3Res10(LatLng(25.0340, 121.5645));
      final ring = H3Service.getVisibilityRing(cell);
      
      expect(ring.length, greaterThan(100));
    });

    test('isWithinDistance detects nearby cells', () {
      final cell1 = H3Service.toH3Res10(LatLng(25.0340, 121.5645));
      final cell2 = H3Service.toH3Res10(LatLng(25.0350, 121.5650)); // Very close
      
      // Should be within k=40
      expect(H3Service.isWithinDistance(cell1, cell2, 40), isTrue);
    });

    test('h3ToLatLng converts back correctly', () {
      final original = LatLng(25.0340, 121.5645);
      final cell = H3Service.toH3Res10(original);
      final converted = H3Service.h3ToLatLng(cell);
      
      // Should be very close (within H3 res=10 precision)
      expect((converted.latitude - original.latitude).abs(), lessThan(0.01));
      expect((converted.longitude - original.longitude).abs(), lessThan(0.01));
    });
  });
}



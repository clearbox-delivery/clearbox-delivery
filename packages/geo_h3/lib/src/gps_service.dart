import 'package:latlong2/latlong.dart';

/// GPS Service
/// Provides current device position with web/dev fallback
/// 
/// Web/Dev mode: returns mock location (Taipei 101)
/// IO/Prod mode: TODO integrate geolocator package in Phase 1+
class GPSService {
  /// Get current position
  /// Returns mock location in web/dev, real GPS in IO/prod
  static Future<LatLng> getCurrentPosition() async {
    // TODO: Platform check and real GPS for mobile
    // For now, return Taipei 101 for web dev
    return const LatLng(25.0340, 121.5645);
  }

  /// Check if location permission granted
  static Future<bool> hasPermission() async {
    // TODO: implement permission check
    return true; // Dev fallback
  }

  /// Request location permission
  static Future<bool> requestPermission() async {
    // TODO: implement permission request
    return true; // Dev fallback
  }

  /// Watch position stream (for courier real-time tracking)
  static Stream<LatLng> watchPosition() async* {
    // TODO: implement real position stream
    // For now, yield mock position every 5 seconds
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield const LatLng(25.0340, 121.5645);
    }
  }
}


// services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  // Fallback location (Bukit Mertajam, Penang)
  static const double fallbackLatitude = 5.4141;
  static const double fallbackLongitude = 100.3288;
  
  static Position? _cachedPosition;
  static bool _usingFallback = false;
  
  /// Get current user location with proper error handling
  static Future<Position> getCurrentLocation() async {
    // Return cached position if available (avoid multiple GPS requests)
    if (_cachedPosition != null) {
      // print('Using cached location: ${_cachedPosition!.latitude}, ${_cachedPosition!.longitude}');
      return _cachedPosition!;
    }
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // print('Location services disabled, using fallback');
        return _getFallbackPosition();
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied) {
        // print('Location permission denied, using fallback');
        return _getFallbackPosition();
      }

      if (permission == LocationPermission.deniedForever) {
        // print('Location permission permanently denied, using fallback');
        return _getFallbackPosition();
      }

      // Get actual position
      // print('Fetching current GPS location...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ GPS timeout, using fallback');
          return _getFallbackPosition();
        },
      );
      
      _cachedPosition = position;
      _usingFallback = false;
      // print('Got GPS location: ${position.latitude}, ${position.longitude}');
      
      return position;
      
    } catch (e) {
      print('Location error: $e');
      return _getFallbackPosition();
    }
  }
  
  /// Get fallback position
  static Position _getFallbackPosition() {
    _usingFallback = true;
    _cachedPosition = Position(
      latitude: fallbackLatitude,
      longitude: fallbackLongitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
    return _cachedPosition!;
  }
  
  /// Check if currently using fallback location
  static bool isUsingFallback() => _usingFallback;
  
  /// Get location info text
  static String getLocationInfoText() {
    if (_usingFallback) {
      return 'Bukit Mertajam, Penang (Fallback)';
    }
    if (_cachedPosition != null) {
      return '${_cachedPosition!.latitude.toStringAsFixed(4)}, ${_cachedPosition!.longitude.toStringAsFixed(4)}';
    }
    return 'Loading...';
  }
  
  /// Clear cached location (force refresh on next call)
  static void clearCache() {
    _cachedPosition = null;
    _usingFallback = false;
    print('🔄 Location cache cleared');
  }
  
  /// Get latitude (with fallback)
  static Future<double> getLatitude() async {
    final position = await getCurrentLocation();
    return position.latitude;
  }
  
  /// Get longitude (with fallback)
  static Future<double> getLongitude() async {
    final position = await getCurrentLocation();
    return position.longitude;
  }
  
  /// Get both coordinates as a tuple
  static Future<(double lat, double lon)> getCoordinates() async {
    final position = await getCurrentLocation();
    return (position.latitude, position.longitude);
  }
  
  /// Calculate distance between two points in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
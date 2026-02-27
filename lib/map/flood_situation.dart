import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'marker.dart';

/// Model representing the AI-predicted situation for a district
class DistrictSituation {
  final String districtName;
  final String riskLevel;
  final double? predictedAreaKm2;
  final String currentWeather;
  final LatLng coord;

  DistrictSituation({
    required this.districtName,
    required this.riskLevel,
    required this.coord,
    this.predictedAreaKm2,
    required this.currentWeather,
  });
}

/// Service to fetch official AI flood situations from backend API
class FloodSituationService {
  static const String _apiUrl =
      'https://predict-flood-453491805144.asia-southeast1.run.app';

  final http.Client _client;

  FloodSituationService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch situations for all supported districts defined in `marker.dart`.
  /// Returns a list of `DistrictSituation` (skips districts that fail).
  Future<List<DistrictSituation>> fetchAllDistrictSituations() async {
    final List<DistrictSituation> results = [];

    for (final entry in supportedDistrictCoordinates.entries) {
      final districtKey = entry.key;
      final coord = entry.value;

      try {
        final resp = await _client.post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'district': districtKey}),
        ).timeout(const Duration(seconds: 10));

        if (resp.statusCode != 200) {
          // skip on non-200
          continue;
        }

        final Map<String, dynamic> jsonData = jsonDecode(resp.body);

        // Map common keys with fallbacks
        final String riskLevel = (jsonData['riskLevel'] ?? jsonData['risk'] ?? 'UNKNOWN').toString();

        // predicted area might be under different keys (predictedArea, Area, area)
        double? predictedArea;
        dynamic rawArea = jsonData['predictedArea'] ?? jsonData['Area'] ?? jsonData['area'];

        if (rawArea != null) {
          if (rawArea is num) {
            predictedArea = rawArea.toDouble();
          } else if (rawArea is String) {
            String cleanArea = rawArea.replaceAll(' km2', '').trim();
            predictedArea = double.tryParse(cleanArea);
          }
        }

        final String currentWeather = (jsonData['currentWeather'] ?? jsonData['weather'] ?? 'Unknown').toString();

        results.add(DistrictSituation(
          districtName: districtKey,
          riskLevel: riskLevel,
          coord: coord,
          predictedAreaKm2: predictedArea,
          currentWeather: currentWeather,
        ));
      } catch (e) {
        // ignore per-district errors and continue
        debugPrint('FloodSituationService fetch error for $districtKey: $e');
        continue;
      }
    }

    return results;
  }
}

/// Convert a list of [DistrictSituation] into Google Maps [Marker]s.
Set<Marker> getSituationMarkers(
  List<DistrictSituation> situations, {
  void Function(DistrictSituation)? onTap,
}) {
  final Set<Marker> markers = {};

  for (final s in situations) {
    final String label = s.districtName.replaceAll('_', ' ');

    // Determine color hue
    final String riskUpper = s.riskLevel.toUpperCase();
    double hue = BitmapDescriptor.hueGreen;

    if (riskUpper.contains('HIGH') || riskUpper.contains('EXTREME')) {
      hue = BitmapDescriptor.hueRed;
    } else if (riskUpper.contains('MEDIUM') || riskUpper.contains('MODERATE')) {
      hue = BitmapDescriptor.hueOrange;
    } else {
      hue = BitmapDescriptor.hueGreen;
    }

    final String areaSnippet = s.predictedAreaKm2 != null
        ? '${s.predictedAreaKm2!.toStringAsFixed(4)} km2'
        : 'Area N/A';

    final Marker marker = Marker(
      markerId: MarkerId('official_${s.districtName}'),
      position: s.coord,
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      infoWindow: InfoWindow(
        title: label,
        snippet: 'Risk: ${s.riskLevel} • $areaSnippet • Weather: ${s.currentWeather}',
      ),
      onTap: () {
        if (onTap != null) onTap(s);
      },
    );

    markers.add(marker);
  }

  return markers;
}

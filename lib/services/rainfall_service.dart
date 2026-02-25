import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Model for a single day's rainfall
class RainfallData {
  final DateTime date;
  final double rainfallMm;
  final String location;
  final String? source;

  RainfallData({
    required this.date,
    required this.rainfallMm,
    required this.location,
    this.source,
  });

  factory RainfallData.fromJson(Map<String, dynamic> json) {
    return RainfallData(
      date: DateTime.parse(json['date']),
      rainfallMm: (json['rainfall'] ?? 0.0).toDouble(),
      location: json['location'] ?? '',
      source: json['source'],
    );
  }
}

/// District → lat/lon coordinates (matches all supported districts)
class DistrictCoordinates {
  static const Map<String, Map<String, double>> coordinates = {
    'Kota_Bharu_Kelantan':     {'lat': 6.1256,  'lon': 102.2386},
    'Kota_Tinggi_Johor':       {'lat': 1.7381,  'lon': 103.8999},
    'Kuantan_Pahang':          {'lat': 3.8077,  'lon': 103.3260},
    'Pekan_Nanas_Johor':       {'lat': 1.5148,  'lon': 103.5141},
    'Penang_Island':           {'lat': 5.4141,  'lon': 100.3288},
    'Rantau_Panjang_Kelantan': {'lat': 6.0196,  'lon': 101.9721},
    'Segamat_Johor':           {'lat': 2.5148,  'lon': 102.8158},
    'Serian_Sarawak':          {'lat': 1.1778,  'lon': 110.5733},
    'Shah_Alam_Selangor':      {'lat': 3.0738,  'lon': 101.5183},
  };
}

/// Analysis result
class RainfallAnomalyAnalysis {
  final double todayRainfall;
  final double last7DaysAverage;
  final double cumulativeRainfall7Days;
  final List<RainfallData> last7DaysData;
  final double ratio;
  final String riskLevel;
  final String riskDescription;
  final String anomalyType;
  final Color riskColor;
  final String recommendation;
  final String locationName;

  RainfallAnomalyAnalysis({
    required this.todayRainfall,
    required this.last7DaysAverage,
    required this.cumulativeRainfall7Days,
    required this.last7DaysData,
    required this.ratio,
    required this.riskLevel,
    required this.riskDescription,
    required this.anomalyType,
    required this.riskColor,
    required this.recommendation,
    this.locationName = 'Unknown',
  });
}

/// Service to fetch rainfall and analyze anomalies
class RainfallAnomalyService {
  /// Fetch rainfall data from Open-Meteo for a given lat/lon
  Future<List<RainfallData>> fetchRainfallData(
    double lat,
    double lon, {
    required String locationName,
    int days = 8,
  }) async {
    try {
      final pastDays = days - 1;

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&daily=precipitation_sum'
        '&past_days=$pastDays'
        '&forecast_days=1'
        '&timezone=auto',
      );

      print('Fetching Open-Meteo rainfall (past $pastDays days + today): $url');

      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('Open-Meteo API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['daily'] == null || data['daily']['time'] == null) {
        throw Exception('Open-Meteo missing daily data');
      }

      final times = List<String>.from(data['daily']['time']);
      final precs = List<dynamic>.from(data['daily']['precipitation_sum']);

      return List.generate(times.length, (i) {
        return RainfallData(
          date: DateTime.parse(times[i]),
          rainfallMm: (precs[i] ?? 0.0).toDouble(),
          location: locationName,
          source: 'Open-Meteo',
        );
      });
    } catch (e) {
      print('Error fetching Open-Meteo rainfall: $e');
      return _generateFallbackRainfall(lat, lon, days, locationName);
    }
  }

  /// Fallback realistic rainfall data
  List<RainfallData> _generateFallbackRainfall(
    double lat,
    double lon,
    int days,
    String locationName,
  ) {
    final now = DateTime.now();
    final isTropical = lat > -30 && lat < 30;
    final isMonsoon = (now.month >= 11 || now.month <= 2);

    return List.generate(days, (index) {
      final daysAgo = (days - 1) - index;
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: daysAgo));

      double base = 0.0;
      if (isTropical && isMonsoon) {
        base = 10.0 + (index % 3) * 20.0;
      } else if (isTropical) {
        base = 5.0 + (index % 4) * 10.0;
      } else {
        base = 2.0 + (index % 5) * 5.0;
      }

      final variation = (index.hashCode % 10 - 5) * 1.5;

      return RainfallData(
        date: date,
        rainfallMm: (base + variation).clamp(0, 200),
        location: locationName,
        source: 'Estimated',
      );
    });
  }

  /// Analyze rainfall anomaly from raw data
  RainfallAnomalyAnalysis analyzeRainfallAnomaly(
    List<RainfallData> rainfallData, {
    String? locationName,
  }) {
    if (rainfallData.isEmpty) throw Exception('No rainfall data');

    final todayRainfall = rainfallData.last.rainfallMm;
    final last7Days = rainfallData.length >= 7
        ? rainfallData.sublist(rainfallData.length - 7)
        : rainfallData;

    final last7DaysExclToday = last7Days.length > 1
        ? last7Days.sublist(0, last7Days.length - 1)
        : last7Days;

    double total = 0, cumulative = 0;
    for (var d in last7DaysExclToday) total += d.rainfallMm;
    for (var d in last7Days) cumulative += d.rainfallMm;

    final avg = last7DaysExclToday.isNotEmpty
        ? total / last7DaysExclToday.length
        : 0.0;

    final ratio = avg > 0.1 ? todayRainfall / avg : todayRainfall / 10.0;

    final risk = _determineRisk(todayRainfall, ratio);

    return RainfallAnomalyAnalysis(
      todayRainfall: todayRainfall,
      last7DaysAverage: avg,
      cumulativeRainfall7Days: cumulative,
      last7DaysData: last7Days,
      ratio: ratio,
      riskLevel: risk['level']!,
      riskDescription: risk['description']!,
      anomalyType: risk['anomalyType']!,
      riskColor: risk['color']! as Color,
      recommendation: risk['recommendation']!,
      locationName: locationName ?? rainfallData.first.location,
    );
  }

  String _formatDistrictName(String district) {
    return district.replaceAll('_', ' ');
  }
  /// Determine risk level from today's rainfall and ratio
  Map<String, dynamic> _determineRisk(double today, double ratio) {
  // Very heavy rain — always extreme regardless of ratio
  if (today >= 60) {
    return {
      'level': 'EXTREME ANOMALY',
      'description': 'Rainfall far above recent average',
      'anomalyType': 'Extreme Anomaly',
      'color': const Color(0xFFDC2626),
      'recommendation': 'Extreme rainfall pattern detected. Check flood prediction for risk assessment.',
    };
  }

  // Heavy rain (30-60mm) OR significant ratio with meaningful rain
  if (today >= 30 || (ratio >= 2.5 && today >= 20)) {
    return {
      'level': 'HIGH ANOMALY',
      'description': 'Rainfall significantly above recent average',
      'anomalyType': 'Significantly Above Normal',
      'color': const Color(0xFFEA580C),
      'recommendation': 'Unusually high rainfall detected. Monitor local conditions.',
    };
  }

  // Moderate rain or mildly above average (your screenshot case: 15.7mm at 4x → lands here)
  if (today >= 10 || ratio >= 1.5) {
    return {
      'level': 'ELEVATED',
      'description': 'Rainfall above recent average',
      'anomalyType': 'Above Normal',
      'color': const Color(0xFFFBBF24),
      'recommendation': 'Rainfall is higher than usual. Stay weather-aware.',
    };
  }

  // Light rain, nothing unusual
  return {
    'level': 'NORMAL',
    'description': 'Rainfall within normal range',
    'anomalyType': 'Normal',
    'color': const Color(0xFF10B981),
    'recommendation': 'No unusual rainfall activity detected.',
  };
}

  /// Main entry point — fetch and analyze by district name
  Future<RainfallAnomalyAnalysis> fetchAndAnalyze(
    String district, {
    int days = 8,
  }) async {
    final coords = DistrictCoordinates.coordinates[district];

    if (coords == null) {
      throw Exception('District coordinates not found for: $district');
    }

    final lat = coords['lat']!;
    final lon = coords['lon']!;

    final rainfallData = await fetchRainfallData(
      lat,
      lon,
      locationName: _formatDistrictName(district),
      days: days,
    );

    return analyzeRainfallAnomaly(rainfallData, locationName: _formatDistrictName(district));
  }
}
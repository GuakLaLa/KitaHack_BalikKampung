import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'weather_service.dart';

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
  final GoogleWeatherService _weatherService = GoogleWeatherService();

  /// Fetch rainfall data from Open-Meteo (includes past days + today)
  Future<List<RainfallData>> fetchRainfallData(
    double lat,
    double lon, {
    int days = 8, // 7 past days + today
  }) async {
    try {
      final now = DateTime.now();

      // Open-Meteo Forecast API supports past_days parameter
      // This gets us historical data + today's forecast/observation
      final pastDays = days - 1; // e.g., if days=8, get 7 past days + today

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast' 
        '?latitude=$lat&longitude=$lon'
        '&daily=precipitation_sum'
        '&past_days=$pastDays' // ← Get past days
        '&forecast_days=1' // ← Get today
        '&timezone=auto',
      );

      print('Fetching Open-Meteo rainfall (past $pastDays days + today): $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode != 200) {
        throw Exception('Open-Meteo API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['daily'] == null || data['daily']['time'] == null) {
        throw Exception('Open-Meteo missing daily data');
      }

      final times = List<String>.from(data['daily']['time']);
      final precs = List<dynamic>.from(data['daily']['precipitation_sum']);

      final locationName = await _weatherService.getLocationName(lat, lon);

      final rainfallData = List.generate(times.length, (i) {
        return RainfallData(
          date: DateTime.parse(times[i]),
          rainfallMm: (precs[i] ?? 0.0).toDouble(),
          location: locationName,
          source: 'Open-Meteo',
        );
      });

      // print('Fetched ${rainfallData.length} days of rainfall from Open-Meteo');
      // print('   Range: ${times.first} to ${times.last}');
      // print('   Today (${times.last}): ${precs.last}mm');
      
      return rainfallData;
    } catch (e) {
      print('Error fetching Open-Meteo rainfall: $e');
      return _generateFallbackRainfall(lat, lon, days);
    }
  }

  /// Fallback realistic rainfall data
  List<RainfallData> _generateFallbackRainfall(double lat, double lon, int days) {
    final now = DateTime.now();
    final isTropical = lat > -30 && lat < 30;
    final isMonsoon = (now.month >= 11 || now.month <= 2);

    final locationName = 'Bukit Mertajam'; // fallback location

    return List.generate(days, (index) {
      final daysAgo = (days - 1) - index;
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: daysAgo));

      double base = 0.0;
      if (isTropical && isMonsoon) base = 10.0 + (index % 3) * 20.0;
      else if (isTropical) base = 5.0 + (index % 4) * 10.0;
      else base = 2.0 + (index % 5) * 5.0;

      final variation = (index.hashCode % 10 - 5) * 1.5;

      return RainfallData(
        date: date,
        rainfallMm: (base + variation).clamp(0, 200),
        location: locationName,
        source: 'Estimated',
      );
    });
  }

  /// Analyze rainfall anomaly
  RainfallAnomalyAnalysis analyzeRainfallAnomaly(
      List<RainfallData> rainfallData,
      {String? locationName}) {
    if (rainfallData.isEmpty) throw Exception('No rainfall data');

    final todayRainfall = rainfallData.last.rainfallMm;
    final last7Days = rainfallData.length >= 7
        ? rainfallData.sublist(rainfallData.length - 7)
        : rainfallData;

    final last7DaysExclToday =
        last7Days.length > 1 ? last7Days.sublist(0, last7Days.length - 1) : last7Days;

    double total = 0, cumulative = 0;
    for (var d in last7DaysExclToday) total += d.rainfallMm;
    for (var d in last7Days) cumulative += d.rainfallMm;

    final avg = last7DaysExclToday.isNotEmpty ? total / last7DaysExclToday.length : 0.0;

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

  /// Determine risk level
  Map<String, dynamic> _determineRisk(double today, double ratio) {
    if (ratio < 1.2 && today < 20) {
      return {
        'level': '✅ NORMAL',
        'description': 'Rainfall within normal range',
        'anomalyType': 'Normal',
        'color': const Color(0xFF10B981),
        'recommendation': 'NORMAL: No immediate action required.',
      };
    } else if (ratio >= 1.2 && ratio < 2.0) {
      return {
        'level': '🟡 ELEVATED',
        'description': 'Rainfall above normal',
        'anomalyType': 'Above Normal',
        'color': const Color(0xFFFBBF24),
        'recommendation': 'Monitor areas for increased water levels.',
      };
    } else if (ratio >= 2.0 && ratio < 3.0 || today >= 40) {
      return {
        'level': '🟠 HIGH ANOMALY',
        'description': 'Rainfall significantly higher than recent days',
        'anomalyType': 'Significantly Above Normal',
        'color': const Color(0xFFEA580C),
        'recommendation': 'Prepare for potential flooding.',
      };
    } else {
      return {
        'level': '🔴 EXTREME ANOMALY',
        'description': 'Extreme rainfall event detected',
        'anomalyType': 'Extreme Anomaly',
        'color': const Color(0xFFDC2626),
        'recommendation': 'Immediate action required: Flash floods likely.',
      };
    }
  }

  /// Fetch rainfall and analyze anomaly in one call
  Future<RainfallAnomalyAnalysis> fetchAndAnalyze(
    double lat,
    double lon, {
    int days = 8, // 7 past days + today
  }) async {
    final rainfallData = await fetchRainfallData(lat, lon, days: days);
    final locationName = await _weatherService.getLocationName(lat, lon);
    return analyzeRainfallAnomaly(rainfallData, locationName: locationName);
  }
}
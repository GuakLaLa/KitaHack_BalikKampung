import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:floodsense/home/flood_forecast.dart';

class FloodPredictionResponse {
  final String location;
  final String riskLevel;
  final String predictedArea;
  final String? floodReminder;
  final int? daysUntilFlood;
  final List<FloodForecast> forecast;
  final String currentWeather;

  FloodPredictionResponse({
    required this.location,
    required this.riskLevel,
    required this.predictedArea,
    this.floodReminder,
    this.daysUntilFlood,
    this.forecast = const [],
    this.currentWeather = 'Unknown',
  });

  factory FloodPredictionResponse.fromJson(Map<String, dynamic> json) {
    final forecastJson = json['forecast'] as List<dynamic>?;
    final forecastList = forecastJson != null
        ? forecastJson
            .map((e) => FloodForecast.fromJson(e as Map<String, dynamic>))
            .toList()
        : <FloodForecast>[];

    return FloodPredictionResponse(
      location: json['location'] as String,
      riskLevel: json['riskLevel'] as String,
      predictedArea: json['predictedArea'] as String,
      floodReminder: json['floodReminder'] as String?,
      daysUntilFlood: json['daysUntilFlood'] as int?,
      forecast: forecastList,
      currentWeather: (json['currentWeather'] as String?) ?? 'Unknown',
    );
  }
} 

class FloodService {
  static const String _baseUrl =
      'https://predict-flood-453491805144.asia-southeast1.run.app';

  static const List<String> supportedDistricts = [
    'Kota_Bharu_Kelantan',
    'Kota_Tinggi_Johor',
    'Kuantan_Pahang',
    'Pekan_Nanas_Johor',
    'Penang_Island',
    'Rantau_Panjang_Kelantan',
    'Segamat_Johor',
    'Serian_Sarawak',
    'Shah_Alam_Selangor',
  ];

  /// Fetch flood prediction for a given district
  static Future<FloodPredictionResponse> getFloodPrediction(
      String district) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'district': district,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
          'Request timed out. Please try again.',
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return FloodPredictionResponse.fromJson(json);
      } else {
        throw Exception(
          'Failed to fetch prediction. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Convert district name to display format
  static String getDisplayName(String district) {
    return district.replaceAll('_', ' ');
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

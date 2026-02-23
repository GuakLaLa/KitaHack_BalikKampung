import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';


// Weather data model
class WeatherData {
  final String dayLabel;
  final double tempC;
  final double tempMinC;
  final double tempMaxC;
  final double feelsLikeC;
  final String condition;
  final String iconCode;
  final double precipitationMm;
  final double humidity;
  final double windSpeedKmh;
  final double uvIndex;
  final int cloudCoverPercent;
  final DateTime dateTime;

  WeatherData({
    required this.dayLabel,
    required this.tempC,
    required this.tempMinC,
    required this.tempMaxC,
    required this.feelsLikeC,
    required this.condition,
    required this.iconCode,
    required this.precipitationMm,
    required this.humidity,
    required this.windSpeedKmh,
    required this.uvIndex,
    required this.cloudCoverPercent,
    required this.dateTime,
  });

  factory WeatherData.fromGoogleWeather(
    Map<String, dynamic> json,
    String dayLabel,
    int dayIndex,
  ) {
    try {
      // Extract daytime and nighttime forecasts
      final daytime = json['daytimeForecast'] ?? {};
      final nighttime = json['nighttimeForecast'] ?? {};

      // Weather condition (use daytime)
      final weatherCondition = daytime['weatherCondition'] ?? {};
      final description = weatherCondition['description'] ?? {};

      // Temperatures
      final maxTemp = json['maxTemperature'] ?? {};
      final minTemp = json['minTemperature'] ?? {};
      final feelsLikeMax = json['feelsLikeMaxTemperature'] ?? {};
      
      final maxTempC = (maxTemp['degrees'] ?? 30.0).toDouble();
      final minTempC = (minTemp['degrees'] ?? 25.0).toDouble();
      final avgTempC = (maxTempC + minTempC) / 2;

      // Precipitation - FIXED: Add day and night
      final dayPrecip = (daytime['precipitation']?['qpf']?['quantity'] ?? 0.0).toDouble();
      final nightPrecip = (nighttime['precipitation']?['qpf']?['quantity'] ?? 0.0).toDouble();
      final precipMm = dayPrecip + nightPrecip;

      // Humidity
      final dayHumidity = (daytime['relativeHumidity'] ?? 60).toDouble();
      final nightHumidity = (nighttime['relativeHumidity'] ?? 60).toDouble();
      final avgHumidity = (dayHumidity + nightHumidity) / 2;

      // Wind
      final wind = daytime['wind'] ?? {};
      final windSpeed = wind['speed'] ?? {};
      final windKmh = (windSpeed['value'] ?? 0.0).toDouble();

      // UV Index
      final uvIndex = (daytime['uvIndex'] ?? 5).toDouble();

      // Cloud cover
      final cloudCover = (daytime['cloudCover'] ?? 0).toInt();

      // Date
      final displayDate = json['displayDate'] ?? {};
      final year = displayDate['year'] ?? DateTime.now().year;
      final month = displayDate['month'] ?? DateTime.now().month;
      final day = displayDate['day'] ?? DateTime.now().day;

      // Icon
      String iconUri = weatherCondition['iconBaseUri'] ?? '';
      String iconName = iconUri.split('/').last;
      if (iconName.isEmpty) iconName = 'partly_cloudy';

      // print('Day $dayIndex: $year-$month-$day | Temp: ${avgTempC.toStringAsFixed(1)}°C | Precip: ${precipMm.toStringAsFixed(1)}mm | Humidity: ${avgHumidity.toStringAsFixed(0)}%');

      return WeatherData(
        dayLabel: dayLabel,
        tempC: avgTempC,
        tempMinC: minTempC,
        tempMaxC: maxTempC,
        feelsLikeC: (feelsLikeMax['degrees'] ?? avgTempC).toDouble(),
        condition: description['text'] ?? 'Clear',
        iconCode: iconName,
        precipitationMm: precipMm,
        humidity: avgHumidity,
        windSpeedKmh: windKmh,
        uvIndex: uvIndex,
        cloudCoverPercent: cloudCover,
        dateTime: DateTime(year, month, day),
      );
    } catch (e) {
      print('Error parsing weather data for day $dayIndex: $e');
      rethrow;
    }
  }
}

// Google Weather Service
class GoogleWeatherService {
  static String get _googleApiKey =>
      dotenv.env['googleApiKey'] ?? '';

  // Fetch forecast
  Future<List<WeatherData>> fetchDailyForecast(
    double lat,
    double lon, {
    int days = 7,
  }) async {
    if (_googleApiKey.isEmpty) {
      print('❌ GOOGLE_API_KEY missing');
      return _getFallbackWeatherData(lat, lon, days);
    }
    try {
      print('Fetching weather for $lat, $lon (requested: $days days)');

      final result = await _tryGoogleWeatherAPI(lat, lon, days);
      if (result != null && result.isNotEmpty) {
        print('Got ${result.length} days from Google Weather API');
        
        if (result.length < days) {
          print('Extending to $days days');
          return _extendForecast(result, days);
        }
        return result;
      }

      print('API failed, using fallback');
      return _getFallbackWeatherData(lat, lon, days);
    } catch (e) {
      print('fetchDailyForecast error: $e');
      return _getFallbackWeatherData(lat, lon, days);
    }
  }

  // Primary API call
  Future<List<WeatherData>?> _tryGoogleWeatherAPI(
    double lat,
    double lon,
    int days,
  ) async {
    try {
      final requestDays = days.clamp(1, 15);

      final url = Uri.parse(
        "https://weather.googleapis.com/v1/forecast/days:lookup?"
        "key=$_googleApiKey&"
        "location.latitude=$lat&"
        "location.longitude=$lon&"
        "days=$requestDays",
      );

      print('API Request: ${url.toString().replaceAll(_googleApiKey, "***")}');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      print('API Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseGoogleWeatherResponse(data);
      } else {
        print('API error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Google Weather API error: $e');
      return null;
    }
  }

  // Parse API response
  List<WeatherData> _parseGoogleWeatherResponse(
    Map<String, dynamic> data,
  ) {
    try {
      final forecastDays = data['forecastDays'] as List? ?? [];
      if (forecastDays.isEmpty) {
        print('No forecast days in response');
        return [];
      }

      // print('Parsing ${forecastDays.length} forecast days from API');

      // Sort by date to ensure correct order
      final sortedForecasts = List<Map<String, dynamic>>.from(forecastDays);
      sortedForecasts.sort((a, b) {
        final aDate = a['displayDate'] ?? {};
        final bDate = b['displayDate'] ?? {};
        
        final aYear = aDate['year'] ?? 0;
        final bYear = bDate['year'] ?? 0;
        final aMonth = aDate['month'] ?? 0;
        final bMonth = bDate['month'] ?? 0;
        final aDay = aDate['day'] ?? 0;
        final bDay = bDate['day'] ?? 0;
        
        final dateA = DateTime(aYear, aMonth, aDay);
        final dateB = DateTime(bYear, bMonth, bDay);
        
        return dateA.compareTo(dateB);
      });

      // Determine correct day labels based on actual dates
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      final result = <WeatherData>[];
      
      for (int i = 0; i < sortedForecasts.length; i++) {
        final forecast = sortedForecasts[i];
        final displayDate = forecast['displayDate'] ?? {};
        final forecastDate = DateTime(
          displayDate['year'] ?? today.year,
          displayDate['month'] ?? today.month,
          displayDate['day'] ?? today.day,
        );
        
        // Calculate day label based on actual date
        final dayDiff = forecastDate.difference(todayDate).inDays;
        String dayLabel;
        
        if (dayDiff == 0) {
          dayLabel = 'Today';
        } else if (dayDiff == 1) {
          dayLabel = 'Tomorrow';
        } else if (dayDiff < 0) {
          // Skip past dates
          print('⏭️ Skipping past date: ${forecastDate.toString().split(' ')[0]}');
          continue;
        } else {
          const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
          dayLabel = days[forecastDate.weekday % 7];
        }

        result.add(
          WeatherData.fromGoogleWeather(forecast, dayLabel, result.length),
        );
      }

      print('Successfully parsed ${result.length} valid forecast days');
      return result;
      
    } catch (e) {
      print('Error parsing response: $e');
      return [];
    }
  }

  List<WeatherData> _extendForecast(
    List<WeatherData> existing,
    int targetDays,
  ) {
    if (existing.isEmpty) return existing;
    
    final extended = List<WeatherData>.from(existing);

    // Calculate realistic averages from existing data
    double avgTemp = 0, avgMinTemp = 0, avgMaxTemp = 0;
    double avgPrecip = 0, avgHumidity = 0, avgWind = 0;
    int rainyDays = 0;

    for (var d in existing) {
      avgTemp += d.tempC;
      avgMinTemp += d.tempMinC;
      avgMaxTemp += d.tempMaxC;
      avgPrecip += d.precipitationMm;
      avgHumidity += d.humidity;
      avgWind += d.windSpeedKmh;
      if (d.precipitationMm > 1.0) rainyDays++;
    }

    final count = existing.length;
    avgTemp /= count;
    avgMinTemp /= count;
    avgMaxTemp /= count;
    avgPrecip /= count;
    avgHumidity /= count;
    avgWind /= count;
    
    // Calculate rain probability
    final rainProbability = rainyDays / count;

    // print('Extension stats: avgTemp=${avgTemp.toStringAsFixed(1)}°C, avgPrecip=${avgPrecip.toStringAsFixed(1)}mm, rainProb=${(rainProbability * 100).toStringAsFixed(0)}%');

    // Get the last date and add days from there
    var currentDate = existing.last.dateTime;
    
    for (int i = existing.length; i < targetDays; i++) {
      currentDate = currentDate.add(const Duration(days: 1));
      
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final dayLabel = days[currentDate.weekday % 7];
      
      // Add slight random variation (±1.5°C)
      final tempVariation = ((i * 7) % 3 - 1) * 1.5;
      
      // Determine if this day should have rain based on probability
      final shouldRain = (i % 3) < (rainProbability * 3);
      
      // Choose condition based on rain
      String condition;
      String iconCode;
      double precipitation;
      
      if (shouldRain && avgPrecip > 2) {
        // Use actual rainy conditions from the data
        final rainyDays = existing.where((d) => d.precipitationMm > 1.0).toList();
        if (rainyDays.isNotEmpty) {
          final randomRainy = rainyDays[i % rainyDays.length];
          condition = randomRainy.condition;
          iconCode = randomRainy.iconCode;
          precipitation = avgPrecip * (0.8 + (i % 5) * 0.1); // 0.8x to 1.2x average
        } else {
          condition = 'Scattered Showers';
          iconCode = 'scattered_showers';
          precipitation = avgPrecip;
        }
      } else {
        // Use actual clear/cloudy conditions from the data
        final clearDays = existing.where((d) => d.precipitationMm <= 1.0).toList();
        if (clearDays.isNotEmpty) {
          final randomClear = clearDays[i % clearDays.length];
          condition = randomClear.condition;
          iconCode = randomClear.iconCode;
          precipitation = 0.0;
        } else {
          condition = 'Partly Cloudy';
          iconCode = 'partly_cloudy';
          precipitation = 0.0;
        }
      }
      
      extended.add(
        WeatherData(
          dayLabel: dayLabel,
          tempC: avgTemp + tempVariation,
          tempMinC: avgMinTemp + tempVariation,
          tempMaxC: avgMaxTemp + tempVariation,
          feelsLikeC: avgTemp + tempVariation + 1,
          condition: condition,
          iconCode: iconCode,
          precipitationMm: precipitation,
          humidity: avgHumidity + ((i % 2) * 5 - 2), // ±2% variation
          windSpeedKmh: avgWind,
          uvIndex: existing.last.uvIndex,
          cloudCoverPercent: shouldRain ? 75 : 40,
          dateTime: currentDate,
        ),
      );
      
      // print('Extended day ${i + 1}: $dayLabel (${currentDate.toString().split(' ')[0]}) - ${(avgTemp + tempVariation).toStringAsFixed(1)}°C, ${precipitation.toStringAsFixed(1)}mm, $condition');
    }

    return extended;
  }

  /// Fallback weather (only used if API completely fails)
  List<WeatherData> _getFallbackWeatherData(
    double lat,
    double lon,
    int days,
  ) {
    print('Using fallback weather data');
    
    final isTropical = lat.abs() < 30;
    final today = DateTime.now();

    return List.generate(days, (i) {
      final date = DateTime(today.year, today.month, today.day).add(Duration(days: i));
      final base = isTropical ? 27.0 : 22.0;
      final variation = ((i * 7) % 3 - 1) * 2.0;
      
      String dayLabel;
      if (i == 0) {
        dayLabel = 'Today';
      } else if (i == 1) {
        dayLabel = 'Tomorrow';
      } else {
        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        dayLabel = dayNames[date.weekday % 7];
      }
      
      final isRainy = i % 3 == 1;
      
      return WeatherData(
        dayLabel: dayLabel,
        tempC: base + variation,
        tempMinC: base + variation - 4,
        tempMaxC: base + variation + 4,
        feelsLikeC: base + variation + 2,
        condition: isRainy ? 'Scattered Showers' : 'Partly Cloudy',
        iconCode: isRainy ? 'scattered_showers' : 'partly_cloudy',
        precipitationMm: isRainy ? 8.5 : 0.2,
        humidity: 70 + (i % 3) * 5,
        windSpeedKmh: 12,
        uvIndex: isTropical ? 8 : 5,
        cloudCoverPercent: isRainy ? 85 : 40,
        dateTime: date,
      );
    });
  }

  // Get location name from lat/lon
  Future<String> getLocationName(double lat, double lon) async {
    try {
      final geocodingUrl = Uri.parse(
        "https://maps.googleapis.com/maps/api/geocode/json?"
        "latlng=$lat,$lon&"
        "key=$_googleApiKey",
      );

      final response = await http.get(geocodingUrl).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {

          final components = data['results'][0]['address_components'];

          final priorities = [
            'sublocality_level_1',
            'sublocality',
            'locality',
            'administrative_area_level_2',
            'administrative_area_level_1',
          ];

          for (String priority in priorities) {
            for (var component in components) {
              final types = List<String>.from(component['types']);
              if (types.contains(priority)) {
                return component['long_name'];
              }
            }
          }

          final formatted = data['results'][0]['formatted_address'] ?? '';
          if (formatted.isNotEmpty) {
            return formatted.split(',').first.trim();
          }
        }
      }
    } catch (e) {
      print('getLocationName error: $e');
    }

    if (lat >= 5 && lat <= 6 && lon >= 100 && lon <= 101) {
      return 'Bukit Mertajam';
    }

    return 'Unknown Location';
  }
}
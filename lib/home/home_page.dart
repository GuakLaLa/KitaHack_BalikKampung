import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floodsense/profile/notifications.dart';
import 'package:floodsense/services/rainfall_service.dart';
import 'package:flutter/material.dart';
import 'package:floodsense/home/flood_prediction.dart';
import 'package:floodsense/home/flood_forecast.dart';
import 'package:floodsense/home/flood_timer.dart';
import 'package:floodsense/services/flood_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'rainfall_anomaly.dart';
import 'weather_forecast.dart';
import 'reminder_checklist.dart';
import 'package:floodsense/services/location_service.dart';

class HomePage extends StatefulWidget {
  final String selectedDistrict;
  final ValueChanged<String> onDistrictChanged;

  const HomePage({
    super.key,
    required this.selectedDistrict,
    required this.onDistrictChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  static const _prefsKey = 'flood_alert_last_shown';

  FloodPredictionResponse? _floodData;
  bool _isLoading = false;
  String? _errorMessage;

  // keep track of the selected district locally so it survives rebuilds
  late String _selectedDistrict;

  // Location
  double? latitude;
  double? longitude;
  bool isLocationLoading = true;
  
  // Prevent notification spam
  String? _lastAnomalyType;
  String? _lastRiskLevel;
  String? _lastNotifiedDistrict;
  
  // District coordinates (lat, lon)
  static const Map<String, List<double>> DISTRICT_COORDS = {
    'Shah_Alam_Selangor': [3.0697, 101.5037],
    'Kota_Bharu_Kelantan': [6.1254, 102.2386],
    'Segamat_Johor': [2.5065, 102.8158],
    'Kuantan_Pahang': [3.8077, 103.3260],
    'Pekan_Nanas_Johor': [1.5086, 103.5097],
    'Penang_Island': [5.3496, 100.2525],
    'Rantau_Panjang_Kelantan': [6.0210, 102.0837],
    'Serian_Sarawak': [1.1693, 110.5689],
    'Kota_Tinggi_Johor': [1.7381, 103.8999],
  };

  @override
  void initState() {
    super.initState();
    _selectedDistrict = widget.selectedDistrict;
    // Set default district to first one
    _fetchFloodData(_selectedDistrict);
    _initAll();
  }

  Future<void> _initAll() async {
    final pos = await _getUserLocation();
    if (pos != null) {
      await _findNearestDistrict(pos);
    }// Fetch initial data
  }

  // Get user's location lat long
  Future<Position?> _getUserLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
        isLocationLoading = false;
      });

      return position;
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        latitude = LocationService.fallbackLatitude;
        longitude = LocationService.fallbackLongitude;
        isLocationLoading = false;
      });
      return null;
    }
  }

  /// Finds the nearest district from the given [userPos] and updates selection.
  Future<void> _findNearestDistrict(Position userPos) async {
    String? nearest;
    double minDist = double.infinity;

    for (final district in FloodService.supportedDistricts) {
      final coords = DISTRICT_COORDS[district];
      if (coords == null || coords.length < 2) continue;
      final lat = coords[0];
      final lon = coords[1];
      final distKm = LocationService.calculateDistance(
        userPos.latitude,
        userPos.longitude,
        lat,
        lon,
      );
      if (distKm < minDist) {
        minDist = distKm;
        nearest = district;
      }
    }

    if (nearest != null && nearest != _selectedDistrict) {
      _selectedDistrict = nearest;
      widget.onDistrictChanged(nearest);
      await _fetchFloodData(nearest);
    }
  }


  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch when parent changes the district
    if (oldWidget.selectedDistrict != widget.selectedDistrict) {
      _selectedDistrict = widget.selectedDistrict;
      _fetchFloodData(widget.selectedDistrict);
    }
  }

  String? _currentDistrict;

  Future<void> _fetchFloodData(String district) async {
    // if we already fetched and the same district, skip reloading
    if (_floodData != null && _currentDistrict == district) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await FloodService.getFloodPrediction(district);
      setState(() {
        _floodData = data;
        _currentDistrict = district;
        _isLoading = false;
      });

      // Check if we should show the alert dialog
      _maybeShowFloodAlert(data);
      _checkNotificationConditions(data);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkNotificationConditions(FloodPredictionResponse data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final prefs = userDoc.data();
    if (prefs == null) return;

    final bool floodEnabled = prefs['floodAlert'] ?? false;
    final bool rainfallEnabled = prefs['rainfallAlert'] ?? false;

    // Flood Risk Notification with district-aware suppression
    if (floodEnabled &&
        data.riskLevel.toLowerCase() == "high" &&
        (_lastNotifiedDistrict != _selectedDistrict ||
        _lastRiskLevel != data.riskLevel)) {

      // Update last notified values
      _lastRiskLevel = data.riskLevel;
      _lastNotifiedDistrict = _selectedDistrict;

      await NotificationService.showFloodAlert(data.location);
    }

    //Rainfall Anomaly Notification
    if (rainfallEnabled) {
      try {
        final analysis = await RainfallAnomalyService()
            .fetchAndAnalyze(_selectedDistrict);

        print("Rainfall ratio: ${analysis.ratio}");
        print("Today rainfall: ${analysis.todayRainfall}");
        print("Anomaly: ${analysis.anomalyType}");

        if (analysis.ratio > 1.2 &&
            analysis.anomalyType != _lastAnomalyType) {

          _lastAnomalyType = analysis.anomalyType;

          await NotificationService.showRainfallAlert(
            location: analysis.locationName,
            anomalyType: analysis.anomalyType,
            rainfall: analysis.todayRainfall,
          );
        }
      } catch (e) {
        print("Rainfall anomaly error: $e");
      }
    }
  }

  Future<void> _maybeShowFloodAlert(FloodPredictionResponse data) async {
    final int? daysUntilFlood = data.daysUntilFlood;

    if (daysUntilFlood == null) return;
    if (daysUntilFlood > 3) return;

    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_prefsKey);
    final today = DateTime.now().toIso8601String().split('T').first;

    if (lastShown == today) return;

    // show dialog
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FloodAlertDialog(daysUntilFlood: daysUntilFlood),
    );

    // store that we showed today
    await prefs.setString(_prefsKey, today);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required when using AutomaticKeepAliveClientMixin
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // District Dropdown Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: _selectedDistrict,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                hint: const Text('Select a district'),
                items: FloodService.supportedDistricts.map((district) {
                  return DropdownMenuItem<String>(
                    value: district,
                    child: Text(FloodService.getDisplayName(district)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedDistrict) {
                    setState(() {
                      _selectedDistrict = newValue;   //UPDATE LOCAL STATE
                      _floodData = null;             //optional: force refresh UI
                    });

                    widget.onDistrictChanged(newValue);  //notify parent
                    _fetchFloodData(newValue);           //fetch new data
                  }
                }
              ),
            ),

            // Error Message Display
            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Loading Indicator or Flood Prediction Card
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Fetching flood prediction...'),
                  ],
                ),
              )
            else if (_floodData != null)
              GestureDetector(
                onTap: _floodData!.floodReminder != null
                    ? () {
                        showDialog(
                          context: context,
                          builder: (_) => FloodAlertDialog(
                            daysUntilFlood: _floodData!.daysUntilFlood ?? 0,
                          ),
                        );
                      }
                    : null,
                child: FloodPredictionCard(
                  location: _floodData!.location,
                  riskLevel: _floodData!.riskLevel,
                  waterDepth: _floodData!.predictedArea,
                  weather: _floodData!.currentWeather,
                  date: DateTime.now().toString().split(' ')[0],
                  floodReminder: _floodData!.floodReminder,
                  daysUntilFlood: _floodData!.daysUntilFlood,
                ),
              ),

            // 3-Day Flood Forecast (from API)
            if (_floodData != null)
              FloodForecastList(forecasts: _floodData!.forecast),

            // Rainfall Anomaly Detection — uses district for consistent location
            RainfallAnomalyCard(
              selectedDistrict: _selectedDistrict,
            ),

            // 7-Day Weather Forecast — uses district for consistent location
            WeatherForecastCard(
              selectedDistrict: _selectedDistrict,
            ),

            // Reminder Checklist
            const ReminderChecklistCard(),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFA6E3E9),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
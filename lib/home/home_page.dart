import 'package:flutter/material.dart';
import 'package:floodsense/home/flood_prediction.dart';
import 'package:floodsense/home/flood_forecast.dart';
import 'package:floodsense/home/flood_timer.dart';
import 'package:floodsense/services/flood_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _prefsKey = 'flood_alert_last_shown';

  String? _selectedDistrict;
  FloodPredictionResponse? _floodData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Set default district to first one
    _selectedDistrict = FloodService.supportedDistricts.first;
    // Fetch initial data
    _fetchFloodData(_selectedDistrict!);
  }

  Future<void> _fetchFloodData(String district) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await FloodService.getFloodPrediction(district);
      setState(() {
        _floodData = data;
        _isLoading = false;
      });

      // Check if we should show the alert dialog
      _maybeShowFloodAlert(data);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _maybeShowFloodAlert(FloodPredictionResponse data) async {
    final int? daysUntilFlood = data.daysUntilFlood;

    if (daysUntilFlood == null) return;
    if (daysUntilFlood > 3) return; // only show if within 3 days

    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString(_prefsKey);
    final today = DateTime.now().toIso8601String().split('T').first;

    if (lastShown == today) return; // already shown today

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
    // Forecasts are now provided by the API via _floodData
    // The list below is intentionally empty; we'll display the API data when available.

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // District Dropdown Selector
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: _selectedDistrict,
                isExpanded: true,
                underline: SizedBox.shrink(),
                hint: Text('Select a district'),
                items: FloodService.supportedDistricts.map((district) {
                  return DropdownMenuItem<String>(
                    value: district,
                    child: Text(FloodService.getDisplayName(district)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDistrict = newValue;
                    });
                    _fetchFloodData(newValue);
                  }
                },
              ),
            ),

            // Error Message Display
            if (_errorMessage != null) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Loading Indicator or Flood Prediction Card
            if (_isLoading)
              Padding(
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
                  weather: _floodData!.currentWeather, // real-time weather from API
                  date: DateTime.now().toString().split(' ')[0],
                  floodReminder: _floodData!.floodReminder,
                  daysUntilFlood: _floodData!.daysUntilFlood,
                ),
              ),

            // 3-Day Flood Forecast (from API)
            if (_floodData != null) FloodForecastList(forecasts: _floodData!.forecast),
          ],
        ),
      ),
      backgroundColor: Color(0xFFA6E3E9),
    );
  }
}
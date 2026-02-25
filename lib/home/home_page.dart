import 'package:flutter/material.dart';
import 'package:floodsense/home/flood_prediction.dart';
import 'package:floodsense/home/flood_forecast.dart';
import 'package:floodsense/home/flood_timer.dart';
import 'package:floodsense/services/flood_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'rainfall_anomaly.dart';
import 'weather_forecast.dart';
import 'reminder_checklist.dart';

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

class _HomePageState extends State<HomePage> {
  static const _prefsKey = 'flood_alert_last_shown';

  FloodPredictionResponse? _floodData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFloodData(widget.selectedDistrict);
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch when parent changes the district
    if (oldWidget.selectedDistrict != widget.selectedDistrict) {
      _fetchFloodData(widget.selectedDistrict);
    }
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
                value: widget.selectedDistrict,
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
                  if (newValue != null) {
                    widget.onDistrictChanged(newValue); // notify NavigationPage
                    _fetchFloodData(newValue);
                  }
                },
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
              selectedDistrict: widget.selectedDistrict,
            ),

            // 7-Day Weather Forecast — uses district for consistent location
            WeatherForecastCard(
              selectedDistrict: widget.selectedDistrict,
            ),

            // Reminder Checklist
            const ReminderChecklistCard(),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFA6E3E9),
    );
  }
}
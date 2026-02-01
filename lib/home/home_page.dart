import 'package:flutter/material.dart';
import 'package:floodsense/home/flood_prediction.dart';
import 'package:floodsense/home/flood_forecast.dart';
import 'package:floodsense/home/flood_timer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget{
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _prefsKey = 'flood_alert_last_shown';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowFloodAlert();
    });
  }

  Future<void> _maybeShowFloodAlert() async {
    // TODO: replace this placeholder with real AI prediction logic.
    // For now, determine daysUntilFlood from your prediction logic.
    // Example: AI predicts flood in 3 days.
    final int? daysUntilFlood = 3; // null if no flood predicted

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
  Widget build(BuildContext context){
    // Sample 3-day forecast data
    List<FloodForecast> forecasts = [
      FloodForecast(day: 'Today', riskLevel: 'LOW'),
      FloodForecast(day: 'Tomorrow', riskLevel: 'MEDIUM'),
      FloodForecast(day: 'Sun', riskLevel: 'HIGH'),
      FloodForecast(day: 'Mon', riskLevel: 'LOW'),
      FloodForecast(day: 'Tue', riskLevel: 'LOW'),
    ];

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            FloodPredictionCard(
              location: 'Kota Damansara',
              riskLevel: 'LOW',
              waterDepth: '23mm',
              weather: 'Slightly Cloud',
              date: '23/1/2026',
              floodReminder: 'Tomorrow will flood',
            ),

            // 3-Day Flood Forecast
            FloodForecastList(forecasts: forecasts),
          ],
        ),
      ),
      backgroundColor: Color(0xFFA6E3E9),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'flood_timer.dart';

class FloodPredictionCard extends StatelessWidget {
  final String location;
  final String riskLevel;
  final String waterDepth;
  final String weather;
  final String date;
  final Color backgroundColor;
  final String? floodReminder;  // e.g., "Tomorrow will flood", null if no flood
  final int? daysUntilFlood;

  const FloodPredictionCard({
    Key? key,
    required this.location,
    required this.riskLevel,
    required this.waterDepth,
    required this.weather,
    required this.date,
    this.backgroundColor = const Color(0xFF89FF8F),
    this.floodReminder,
    this.daysUntilFlood,
  }) : super(key: key);

  Color getRiskColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return Color(0xFF89FF8F);
      case 'MEDIUM':
        return Color(0xFFFFD700);
      case 'HIGH':
        return Color(0xFFFF6B6B);
      default:
        return Color(0xFFA6E3E9);
    }
  }

  Color getWeatherColor(String weather) {
    if (weather.contains('Cloud')) {
      return Colors.grey[400] ?? Colors.grey;  // Darker gray for heavy clouds
    } else if (weather.contains('Rain')) {
      return Colors.blue[300] ?? Colors.blue;  // Light blue for rain
    } else if (weather.contains('Sun') || weather.contains('Clear')) {
      return Colors.yellow[600] ?? Colors.yellow;  // Yellow for sun
    }
    return Colors.yellow[600] ?? Colors.yellow;
  }

  IconData getWeatherIcon(String weather) {
    if (weather.contains('Cloud')) {
      return Icons.cloud;
    } else if (weather.contains('Rain')) {
      return Icons.cloud_queue;
    } else if (weather.contains('Sun') || weather.contains('Clear')) {
      return Icons.wb_sunny;
    } else {
    return Icons.wb_sunny;}
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = getRiskColor(riskLevel);

    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColor, cardColor.withOpacity(0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location
            Text(
              location,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),

            // Flood Risk Today
            Text(
              'Flood Risk Today',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 16),

            // Risk Level and Weather Icon Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Risk Level
                Text(
                  riskLevel,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                // Weather Icon
                Column(
                  children: [
                    Icon(
                      getWeatherIcon(weather),
                      size: 60,
                      color: getWeatherColor(weather),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 20),

            // Details
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Water Depth',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        waterDepth,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weather',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        weather,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Flood Reminder (only show if there's a flood warning)
            if (floodReminder != null) ...[
              SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => FloodAlertDialog(
                      daysUntilFlood: daysUntilFlood ?? 3,
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFF6B6B), // Red color
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$floodReminder',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

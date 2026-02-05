import 'package:flutter/material.dart';

class FloodForecast {
  final String day;
  final String riskLevel; // LOW, MEDIUM, HIGH
  
  FloodForecast({
    required this.day,
    required this.riskLevel,
  });

  factory FloodForecast.fromJson(Map<String, dynamic> json) {
    return FloodForecast(
      day: json['day'] as String,
      riskLevel: json['riskLevel'] as String,
    );
  }
} 

class FloodForecastCard extends StatelessWidget {
  final FloodForecast forecast;

  const FloodForecastCard({
    Key? key,
    required this.forecast,
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

  String getRiskText(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'LOW':
        return 'LOW';
      case 'MEDIUM':
        return 'MEDIUM';
      case 'HIGH':
        return 'HIGH';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  Widget build(BuildContext context) {
    Color barColor = getRiskColor(forecast.riskLevel);
    
    return Container(
      width: 110,
      margin: EdgeInsets.symmetric(horizontal: 6),
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
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bar Chart Icon
            Container(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Short bar
                  Container(
                    width: 6,
                    height: 15,
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  SizedBox(width: 4),
                  // Medium bar
                  Container(
                    width: 6,
                    height: 30,
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  SizedBox(width: 4),
                  // Tall bar
                  Container(
                    width: 6,
                    height: 45,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),

            // Risk Level Text
            Text(
              getRiskText(forecast.riskLevel),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),

            // Day Text
            Text(
              forecast.day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FloodForecastList extends StatelessWidget {
  final List<FloodForecast> forecasts;

  const FloodForecastList({
    Key? key,
    required this.forecasts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.only(bottom: 12, left: 6),
            child: Text(
              '3-day flood prediction forecast',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,               
              ),
            ),
          ),

          // Horizontal Scroll List
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: forecasts
                  .map((forecast) => FloodForecastCard(forecast: forecast))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

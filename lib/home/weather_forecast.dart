import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherForecastCard extends StatefulWidget {
  final double latitude;
  final double longitude;

  const WeatherForecastCard({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<WeatherForecastCard> createState() => _WeatherForecastCardState();
}

class _WeatherForecastCardState extends State<WeatherForecastCard> {
  final GoogleWeatherService _weatherService = GoogleWeatherService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WeatherData>>(
      future: _weatherService.fetchDailyForecast(
        widget.latitude,
        widget.longitude,
        days: 7,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString());
        }

        final forecasts = snapshot.data ?? [];
        
        if (forecasts.isEmpty) {
          return _buildErrorCard('No weather data available');
        }

        return _buildWeatherCard(forecasts);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading weather data...',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: const Column(
        children: [
          Icon(
            Icons.cloud_off,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 12),
          Text(
            'Weather data unavailable',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(List<WeatherData> forecasts) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-Day Weather Forecast',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ...forecasts.take(3).map((forecast) {
            final index = forecasts.indexOf(forecast);
            return Column(
              children: [
                _buildForecastRow(forecast),
                if (index < 2) const Divider(height: 24),
              ],
            );
          }).toList(),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                _showFullForecast(context, forecasts);
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4).withOpacity(0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'More details',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // API source disclaimer
          Center(
            child: Text(
              'Data from Google Weather API',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastRow(WeatherData forecast) {
    return Row(
      children: [
        // Day label with date
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                forecast.dayLabel,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A5568),
                  fontWeight: FontWeight.w500,
                ),
              ),
              // ✅ NEW: Date in muted color
              Text(
                _formatFullDate(forecast.dateTime),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        // Humidity percentage
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 12,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 2),
              Text(
                '${forecast.humidity.round()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Precipitation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: forecast.precipitationMm > 0 
                ? const Color(0xFF4285F4).withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${forecast.precipitationMm.toStringAsFixed(1)}mm',
            style: TextStyle(
              fontSize: 11,
              color: forecast.precipitationMm > 0 
                  ? const Color(0xFF4285F4)
                  : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Weather icon and temperature
        Icon(
          _getIconFromCondition(forecast.condition),
          color: _getIconColor(_getIconFromCondition(forecast.condition)),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          '${forecast.tempMaxC.round()}° / ${forecast.tempMinC.round()}°',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  String _formatFullDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Color _getIconColor(IconData icon) {
    if (icon == Icons.wb_sunny) {
      return const Color(0xFFFBBF24);
    } else if (icon == Icons.umbrella || icon == Icons.grain) {
      return const Color(0xFF4285F4);
    } else if (icon == Icons.thunderstorm) {
      return const Color(0xFF6366F1);
    } else {
      return const Color(0xFF94A3B8);
    }
  }

  IconData _getIconFromCondition(String condition) {
    final conditionLower = condition.toLowerCase();
    if (conditionLower.contains('rain') || conditionLower.contains('shower') || conditionLower.contains('drizzle')) {
      return Icons.umbrella;
    } else if (conditionLower.contains('thunder') || conditionLower.contains('storm')) {
      return Icons.thunderstorm;
    } else if (conditionLower.contains('cloud') || conditionLower.contains('overcast')) {
      return Icons.cloud;
    } else if (conditionLower.contains('clear') || conditionLower.contains('sun')) {
      return Icons.wb_sunny;
    } else if (conditionLower.contains('partly')) {
      return Icons.wb_cloudy;
    } else {
      return Icons.wb_cloudy;
    }
  }

  void _showFullForecast(BuildContext context, List<WeatherData> forecasts) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '7-Day Weather Forecast',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: forecasts.length,
                separatorBuilder: (context, index) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final forecast = forecasts[index];
                  return _buildDetailedForecastRow(forecast);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedForecastRow(WeatherData forecast) {
  return Row(
    children: [
      Expanded(
        flex: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day label and date in the same row
            Row(
              children: [
                Text(
                  forecast.dayLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(width: 8), // spacing between day and date
                Text(
                  _formatFullDate(forecast.dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4), // optional spacing
            Text(
              forecast.condition,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  size: 14,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 4),
                Text(
                  '${forecast.humidity.round()}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Text(
              '${forecast.precipitationMm.toStringAsFixed(1)}mm',
              style: TextStyle(
                fontSize: 12,
                color: forecast.precipitationMm > 0
                    ? Colors.blue[700]
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      Icon(
        _getIconFromCondition(forecast.condition),
        size: 32,
        color: _getIconColor(_getIconFromCondition(forecast.condition)),
      ),
      const SizedBox(width: 8),
      Text(
        '${forecast.tempMaxC.round()}° / ${forecast.tempMinC.round()}°',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2D3748),
        ),
      ),
    ],
  );
}
}
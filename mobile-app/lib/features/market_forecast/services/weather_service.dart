import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  Future<Map<String, dynamic>?> getWeatherData(
    double lat,
    double lon, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final String start = _formatDate(startDate);
      final String end = _formatDate(endDate);

      final url = Uri.parse(
        '$baseUrl?latitude=$lat&longitude=$lon'
        '&daily=temperature_2m_max,precipitation_sum,wind_speed_10m_max,relative_humidity_2m_mean'
        '&timezone=auto'
        '&start_date=$start'
        '&end_date=$end',
      );

      print('Weather API URL: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Weather API error: ${response.statusCode}');
        print('Weather API body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Weather service error: $e');
      return null;
    }
  }

  Map<String, dynamic>? parseWeatherData(Map<String, dynamic>? data) {
    if (data == null || data['daily'] == null) return null;

    final daily = data['daily'];

    final List dates = daily['time'] ?? [];
    final List temps = daily['temperature_2m_max'] ?? [];
    final List rain = daily['precipitation_sum'] ?? [];
    final List wind = daily['wind_speed_10m_max'] ?? [];
    final List humidity = daily['relative_humidity_2m_mean'] ?? [];

    if (dates.isEmpty ||
        temps.isEmpty ||
        rain.isEmpty ||
        wind.isEmpty ||
        humidity.isEmpty) {
      return null;
    }

    double tempSum = 0;
    double rainSum = 0;
    double windSum = 0;
    double humiditySum = 0;
    int count = 0;

    for (int i = 0; i < dates.length; i++) {
      tempSum += (temps[i] ?? 0).toDouble();
      rainSum += (rain[i] ?? 0).toDouble();
      windSum += (wind[i] ?? 0).toDouble();
      humiditySum += (humidity[i] ?? 0).toDouble();
      count++;
    }

    if (count == 0) return null;

    return {
      'temperature': (tempSum / count).round(),
      'humidity': (humiditySum / count).round(),
      'windSpeed': (windSum / count).round(),
      'rainfall': rainSum.round(),
      //'description': 'Upcoming Week Forecast',
      'location': 'Selected District',
      'daysCount': count,
      'startDate': dates.first,
      'endDate': dates.last,
    };
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

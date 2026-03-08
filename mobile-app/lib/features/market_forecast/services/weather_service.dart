import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String apiKey = '7b669be478460a9274a19e8305eb4ed1';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Map<String, dynamic>?> getWeatherData(
    double lat,
    double lon, {
    String? district,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      );
      if (district != null) {
        'Weather API URL: $url | District: $district';
      } else {
        'Weather API URL: $url';
      }
      final response = await http.get(url);
      // print('Weather API Response Body: \\${response.body}');
      // No request body for GET, but print headers if needed
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        print('Invalid API Key. Please check your OpenWeatherMap API key.');
        return null;
      } else if (response.statusCode == 429) {
        print('API rate limit exceeded. Try again later.');
        return null;
      } else {
        print('Weather API error: \\${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Weather service error: $e');
      return null;
    }
  }

  // Extract relevant weather data
  Map<String, dynamic>? parseWeatherData(Map<String, dynamic>? data) {
    if (data == null) return null;
    return {
      'temperature': data['main']['temp']?.round() ?? 0,
      'humidity': data['main']['humidity'] ?? 0,
      'description': data['weather'][0]['description'] ?? 'Unknown',
      'windSpeed': data['wind']?['speed'] ?? 0,
      'rainfall': data['rain']?['1h'] ?? 0, // Null if no rain
      'location': data['name'] ?? 'Unknown Location',
    };
  }
}

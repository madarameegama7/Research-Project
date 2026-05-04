import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double humidity; // percentage
  final double temperature; // celsius
  final double rainfall; // mm/day
  final List<WeatherEntry> past7Days;
  final DateTime timestamp;
  final int consecutiveRainyDays;
  final String location;
  final String description;
  final double feelsLike;
  final int pressure;
  final int windSpeed;

  WeatherData({
    required this.humidity,
    required this.temperature,
    required this.rainfall,
    required this.past7Days,
    required this.timestamp,
    required this.consecutiveRainyDays,
    required this.location,
    required this.description,
    required this.feelsLike,
    required this.pressure,
    required this.windSpeed,
  });
}

class WeatherEntry {
  final DateTime date;
  final double humidity;
  final double temperature;
  final double rainfall;

  WeatherEntry({
    required this.date,
    required this.humidity,
    required this.temperature,
    required this.rainfall,
  });
}

class WeatherNotification {
  final String type; // 'humidity', 'temperature', 'rainfall'
  final String message;
  final String severity; // 'low', 'normal', 'high'
  final IconType iconType;

  WeatherNotification({
    required this.type,
    required this.message,
    required this.severity,
    required this.iconType,
  });
}

enum IconType { humidity, temperature, rainfall, warning }

class WeatherService {
  // Get weather notifications based on current conditions
  static List<WeatherNotification> getNotifications({
    required double humidity,
    required double temperature,
    required double rainfall,
    required int consecutiveRainyDays,
  }) {
    final notifications = <WeatherNotification>[];

    // Humidity notifications
    if (humidity < 60) {
      notifications.add(
        WeatherNotification(
          type: 'humidity',
          message:
              'Low humidity detected. Pepper plants may experience stress.',
          severity: 'low',
          iconType: IconType.humidity,
        ),
      );
    } else if (humidity >= 70 && humidity <= 85) {
      notifications.add(
        WeatherNotification(
          type: 'humidity',
          message:
              'Humidity is in the optimal range for black pepper growth.',
          severity: 'normal',
          iconType: IconType.humidity,
        ),
      );
    } else if (humidity > 90) {
      notifications.add(
        WeatherNotification(
          type: 'humidity',
          message: 'High humidity detected. Risk of fungal diseases may increase.',
          severity: 'high',
          iconType: IconType.humidity,
        ),
      );
    }

    // Temperature notifications
    if (temperature < 20) {
      notifications.add(
        WeatherNotification(
          type: 'temperature',
          message: 'Low temperature detected. Black pepper growth may slow down.',
          severity: 'low',
          iconType: IconType.temperature,
        ),
      );
    } else if (temperature >= 24 && temperature <= 30) {
      // Check for warm + humid conditions
      if (humidity > 85) {
        notifications.add(
          WeatherNotification(
            type: 'temperature',
            message:
                'Warm and humid conditions detected. Risk of fungal diseases may increase.',
            severity: 'high',
            iconType: IconType.warning,
          ),
        );
      } else {
        notifications.add(
          WeatherNotification(
            type: 'temperature',
            message: 'Temperature is in the optimal range for black pepper growth.',
            severity: 'normal',
            iconType: IconType.temperature,
          ),
        );
      }
    } else if (temperature > 32) {
      notifications.add(
        WeatherNotification(
          type: 'temperature',
          message: 'High temperature detected. Plant stress may increase.',
          severity: 'high',
          iconType: IconType.temperature,
        ),
      );
    } else if (temperature >= 24 && temperature <= 32 && humidity > 85) {
      notifications.add(
        WeatherNotification(
          type: 'temperature',
          message:
              'Warm and humid conditions detected. Risk of fungal diseases may increase.',
          severity: 'high',
          iconType: IconType.warning,
        ),
      );
    }

    // Rainfall notifications
    if (rainfall >= 0 && rainfall < 10) {
      notifications.add(
        WeatherNotification(
          type: 'rainfall',
          message: 'Low rainfall detected. Soil moisture may reduce.',
          severity: 'low',
          iconType: IconType.rainfall,
        ),
      );
    } else if (rainfall >= 10 && rainfall < 40) {
      notifications.add(
        WeatherNotification(
          type: 'rainfall',
          message: 'Moderate rainfall detected. Suitable moisture for pepper growth.',
          severity: 'normal',
          iconType: IconType.rainfall,
        ),
      );
    } else if (rainfall >= 40) {
      notifications.add(
        WeatherNotification(
          type: 'rainfall',
          message:
              'Heavy rainfall detected. Risk of root diseases and fungal infections may increase.',
          severity: 'high',
          iconType: IconType.rainfall,
        ),
      );
    }

    // Prolonged rainfall notification
    if (consecutiveRainyDays >= 3) {
      notifications.add(
        WeatherNotification(
          type: 'rainfall',
          message:
              'Prolonged rainfall detected. High risk of black pepper diseases.',
          severity: 'high',
          iconType: IconType.warning,
        ),
      );
    }

    return notifications;
  }

  // Real API method to fetch weather data from OpenWeatherMap
  static const String apiKey = '6fd3e2cb9788d90b0f15ea15eb62827f';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  static Future<WeatherData> fetchWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric',
      );

      print('🌤️ Fetching weather from: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Weather API request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Weather data received: ${data['name']}');
        return _parseWeatherResponse(data);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API Key. Please check your OpenWeatherMap credentials.');
      } else if (response.statusCode == 404) {
        throw Exception('Location not found. Please check your coordinates.');
      } else {
        throw Exception('Weather API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Weather service error: $e');
      rethrow;
    }
  }

  // Parse OpenWeatherMap API response
  static WeatherData _parseWeatherResponse(Map<String, dynamic> data) {
    final temperature = (data['main']['temp'] as num).toDouble();
    final humidity = (data['main']['humidity'] as num).toDouble();
    final feelsLike = (data['main']['feels_like'] as num).toDouble();
    final pressure = data['main']['pressure'] as int;
    final windSpeed = (data['wind']['speed'] as num).toInt();
    final location = data['name'] as String;
    final description = data['weather'][0]['description'] as String;

    // Rainfall - check if it exists in the API response
    double rainfall = 0.0;
    if (data['rain'] != null) {
      rainfall = (data['rain']['1h'] ?? 0.0) as double;
    }

    return WeatherData(
      humidity: humidity,
      temperature: temperature,
      rainfall: rainfall,
      past7Days: _generateMockPast7Days(), // TODO: Use forecast API for real data
      timestamp: DateTime.now(),
      consecutiveRainyDays: rainfall > 0 ? 1 : 0, // TODO: Track from database
      location: location,
      description: description,
      feelsLike: feelsLike,
      pressure: pressure,
      windSpeed: windSpeed,
    );
  }

  // Search location by city name
  static Future<Map<String, double>> searchLocation(String cityName) async {
    try {
      final url = Uri.parse(
        '$baseUrl/weather?q=$cityName&appid=$apiKey&units=metric',
      );

      print('🔍 Searching location: $cityName');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Location search timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coords = data['coord'];
        print('✅ Location found: ${data['name']}, ${data['sys']['country']}');
        return {
          'latitude': (coords['lat'] as num).toDouble(),
          'longitude': (coords['lon'] as num).toDouble(),
        };
      } else if (response.statusCode == 404) {
        throw Exception('Location "$cityName" not found');
      } else {
        throw Exception('Location search error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Location search error: $e');
      rethrow;
    }
  }

  static List<WeatherEntry> _generateMockPast7Days() {
    final entries = <WeatherEntry>[];
    for (int i = 6; i >= 0; i--) {
      entries.add(
        WeatherEntry(
          date: DateTime.now().subtract(Duration(days: i)),
          humidity: 65 + (i * 2.5),
          temperature: 24 + (i * 0.5),
          rainfall: 10 + (i * 1.5),
        ),
      );
    }
    return entries;
  }
}


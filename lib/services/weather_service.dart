import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Weather data model
class WeatherData {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String condition;
  final String icon;
  final int weatherCode;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.icon,
    required this.weatherCode,
  });

  factory WeatherData.fromOpenMeteo(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final weatherCode = current['weather_code'] as int;
    
    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: current['relative_humidity_2m'] as int,
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: weatherCode,
      condition: _getConditionFromCode(weatherCode),
      icon: _getIconFromCode(weatherCode),
    );
  }

  static String _getConditionFromCode(int code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  static String _getIconFromCode(int code) {
    switch (code) {
      case 0:
        return '☀️';
      case 1:
      case 2:
        return '⛅';
      case 3:
        return '☁️';
      case 45:
      case 48:
        return '🌫️';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return '🌧️';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return '🌧️';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return '❄️';
      case 80:
      case 81:
      case 82:
        return '🌦️';
      case 95:
      case 96:
      case 99:
        return '⛈️';
      default:
        return '🌡️';
    }
  }
}

/// Weather service using Open-Meteo API (FREE, NO API KEY REQUIRED)
class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  WeatherData? _cachedWeather;
  DateTime? _lastFetchTime;
  double? _lastLat;
  double? _lastLon;

  /// Fetch current weather for given coordinates
  /// Uses Open-Meteo API which is completely free and requires no API key
  Future<WeatherData?> getWeather(double latitude, double longitude) async {
    // Check cache - reuse if fetched within last 5 minutes and same location
    if (_cachedWeather != null &&
        _lastFetchTime != null &&
        _lastLat == latitude &&
        _lastLon == longitude &&
        DateTime.now().difference(_lastFetchTime!).inMinutes < 5) {
      return _cachedWeather;
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
        'timezone': 'auto',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedWeather = WeatherData.fromOpenMeteo(json);
        _lastFetchTime = DateTime.now();
        _lastLat = latitude;
        _lastLon = longitude;
        return _cachedWeather;
      } else {
        debugPrint('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      return null;
    }
  }

  /// Clear cached weather data
  void clearCache() {
    _cachedWeather = null;
    _lastFetchTime = null;
    _lastLat = null;
    _lastLon = null;
  }
}

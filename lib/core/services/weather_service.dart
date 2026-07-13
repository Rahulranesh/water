import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

/// Fetches current weather from Open-Meteo (free, no API key needed).
/// Also performs a reverse geocode to get the city name.
class WeatherService {
  const WeatherService();

  static const _weatherBase = 'https://api.open-meteo.com/v1/forecast';
  static const _geoBase = 'https://nominatim.openstreetmap.org/reverse';

  /// Fetches [WeatherData] for [latitude] / [longitude].
  /// Returns null if the request fails.
  Future<WeatherData?> fetchWeather(double latitude, double longitude) async {
    try {
      final weatherUri = Uri.parse(_weatherBase).replace(queryParameters: {
        'latitude': latitude.toStringAsFixed(4),
        'longitude': longitude.toStringAsFixed(4),
        'current_weather': 'true',
        'hourly': 'apparent_temperature',
        'forecast_days': '1',
        'timezone': 'auto',
      });

      final weatherRes = await http
          .get(weatherUri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (weatherRes.statusCode != 200) {
        debugPrint('WeatherService HTTP ${weatherRes.statusCode}');
        return null;
      }

      final body = jsonDecode(weatherRes.body) as Map<String, dynamic>;
      final current = body['current_weather'] as Map<String, dynamic>;
      final tempC = (current['temperature'] as num).toDouble();
      final wmoCode = (current['weathercode'] as num).toInt();

      // Fetch feels-like from first hourly value
      final hourly = body['hourly'] as Map<String, dynamic>?;
      final apparentList = hourly?['apparent_temperature'] as List<dynamic>?;
      final feelsLike =
          apparentList != null && apparentList.isNotEmpty
              ? (apparentList[0] as num).toDouble()
              : tempC;

      final city = await _reverseGeocode(latitude, longitude);

      return WeatherData(
        temperatureC: tempC,
        feelsLikeC: feelsLike,
        city: city,
        condition: WeatherCondition.fromWmoCode(wmoCode),
        fetchedAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      debugPrint('WeatherService error: $e');
      return null;
    }
  }

  /// Reverse-geocodes lat/lon to a human-readable city name using Nominatim.
  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(_geoBase).replace(queryParameters: {
        'lat': lat.toStringAsFixed(4),
        'lon': lon.toStringAsFixed(4),
        'format': 'json',
      });
      final res = await http
          .get(uri, headers: {
            'Accept': 'application/json',
            'User-Agent': 'HydroFlow/1.0',
          })
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return 'Your location';
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;
      if (address == null) return 'Your location';

      return (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              'Your location') as String;
    } catch (_) {
      return 'Your location';
    }
  }
}

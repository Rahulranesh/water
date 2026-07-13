import 'dart:convert';

/// Represents a snapshot of weather data fetched from Open-Meteo.
class WeatherData {
  const WeatherData({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.city,
    required this.condition,
    required this.fetchedAt,
    required this.latitude,
    required this.longitude,
  });

  final double temperatureC;
  final double feelsLikeC;
  final String city;
  final WeatherCondition condition;
  final DateTime fetchedAt;
  final double latitude;
  final double longitude;

  /// True if the data is less than 30 minutes old.
  bool get isFresh =>
      DateTime.now().difference(fetchedAt).inMinutes < 30;

  String get temperatureLabel => '${temperatureC.round()}°C';

  String get conditionEmoji => switch (condition) {
        WeatherCondition.clear => '☀️',
        WeatherCondition.partlyCloudy => '⛅',
        WeatherCondition.cloudy => '☁️',
        WeatherCondition.foggy => '🌫️',
        WeatherCondition.drizzle => '🌦️',
        WeatherCondition.rain => '🌧️',
        WeatherCondition.snow => '❄️',
        WeatherCondition.thunderstorm => '⛈️',
        WeatherCondition.unknown => '🌡️',
      };

  String get conditionLabel => switch (condition) {
        WeatherCondition.clear => 'Clear',
        WeatherCondition.partlyCloudy => 'Partly cloudy',
        WeatherCondition.cloudy => 'Cloudy',
        WeatherCondition.foggy => 'Foggy',
        WeatherCondition.drizzle => 'Drizzle',
        WeatherCondition.rain => 'Rainy',
        WeatherCondition.snow => 'Snowing',
        WeatherCondition.thunderstorm => 'Thunderstorm',
        WeatherCondition.unknown => 'Unknown',
      };

  /// Extra ml of water needed above base goal at this temperature.
  int get temperatureBoostMl {
    final t = temperatureC;
    if (t >= 38) return 800;
    if (t >= 33) return 600;
    if (t >= 28) return 400;
    if (t >= 23) return 200;
    if (t < 15) return -100;
    return 0;
  }

  /// Reminder interval in minutes based on temperature.
  int get reminderIntervalMinutes {
    final t = temperatureC;
    if (t >= 38) return 45;
    if (t >= 30) return 60;
    if (t >= 20) return 75;
    return 90;
  }

  Map<String, dynamic> toJson() => {
        'temperatureC': temperatureC,
        'feelsLikeC': feelsLikeC,
        'city': city,
        'condition': condition.name,
        'fetchedAt': fetchedAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        temperatureC: (json['temperatureC'] as num).toDouble(),
        feelsLikeC: (json['feelsLikeC'] as num).toDouble(),
        city: json['city'] as String,
        condition: WeatherCondition.values.byName(
          json['condition'] as String? ?? 'unknown',
        ),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  static WeatherData? tryDecode(String? raw) {
    if (raw == null) return null;
    try {
      return WeatherData.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}

enum WeatherCondition {
  clear,
  partlyCloudy,
  cloudy,
  foggy,
  drizzle,
  rain,
  snow,
  thunderstorm,
  unknown;

  /// Map from Open-Meteo WMO weather code to condition.
  static WeatherCondition fromWmoCode(int code) {
    if (code == 0) return clear;
    if (code <= 2) return partlyCloudy;
    if (code == 3) return cloudy;
    if (code <= 49) return foggy;
    if (code <= 57) return drizzle;
    if (code <= 67) return rain;
    if (code <= 77) return snow;
    if (code <= 99) return thunderstorm;
    return unknown;
  }
}

enum WeatherFetchState { idle, loading, success, denied, error }

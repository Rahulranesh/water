import 'dart:convert';

import 'package:flutter/material.dart';

import 'weather_model.dart';

enum ActivityLevel { low, moderate, high }

enum Climate { cold, temperate, hotHumid }

enum GoalType { general, weightLoss, fitness, pregnancySafe }

enum UnitSystem { ml, oz }

enum MascotMood { sleepy, steady, cheering, celebrating }

enum DrinkKind {
  water('water', 'Water', 1, Icons.water_drop_rounded, Color(0xFF1FB6FF), '💧'),
  coffee('coffee', 'Coffee', .8, Icons.coffee_rounded, Color(0xFF7B4A2D), '☕'),
  tea(
    'tea',
    'Tea',
    .9,
    Icons.emoji_food_beverage_rounded,
    Color(0xFF23A36B),
    '🍵',
  ),
  juice(
    'juice',
    'Juice',
    .85,
    Icons.local_bar_rounded,
    Color(0xFFFF9F43),
    '🧃',
  ),
  soda(
    'soda',
    'Soda',
    .75,
    Icons.bubble_chart_rounded,
    Color(0xFF8E5CF4),
    '🥤',
  ),
  milk('milk', 'Milk', .9, Icons.local_drink_rounded, Color(0xFFF4F9FF), '🥛'),
  sportsDrink(
    'sports',
    'Sports',
    .95,
    Icons.sports_handball_rounded,
    Color(0xFF00C2A8),
    '⚡',
  ),
  alcohol(
    'alcohol',
    'Alcohol',
    .5,
    Icons.wine_bar_rounded,
    Color(0xFFE25A7B),
    '🍷',
  );

  const DrinkKind(
    this.id,
    this.label,
    this.multiplier,
    this.icon,
    this.color,
    this.emoji,
  );

  final String id;
  final String label;
  final double multiplier;
  final IconData icon;
  final Color color;
  final String emoji;

  DrinkOption get option => DrinkOption(
    id: id,
    label: label,
    multiplier: multiplier,
    color: color,
    emoji: emoji,
    isCustom: false,
  );
}

class DrinkOption {
  const DrinkOption({
    required this.id,
    required this.label,
    required this.multiplier,
    required this.color,
    required this.emoji,
    required this.isCustom,
  });

  final String id;
  final String label;
  final double multiplier;
  final Color color;
  final String emoji;
  final bool isCustom;

  IconData get icon => _builtInKind?.icon ?? Icons.local_drink_rounded;

  DrinkKind? get _builtInKind {
    for (final kind in DrinkKind.values) {
      if (kind.id == id) return kind;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'multiplier': multiplier,
    'color': color.toARGB32(),
    'emoji': emoji,
    'isCustom': isCustom,
  };

  factory DrinkOption.fromJson(Map<String, dynamic> json) {
    return DrinkOption(
      id: json['id'] as String,
      label: json['label'] as String,
      multiplier: (json['multiplier'] as num).toDouble(),
      color: Color(json['color'] as int),
      emoji: json['emoji'] as String,
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.gender,
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.activityLevel,
    required this.climate,
    required this.wakeTime,
    required this.sleepTime,
    required this.goalType,
    required this.dailyGoalMl,
  });

  final String gender;
  final double weightKg;
  final double heightCm;
  final int age;
  final ActivityLevel activityLevel;
  final Climate climate;
  final TimeOfDay wakeTime;
  final TimeOfDay sleepTime;
  final GoalType goalType;
  final int dailyGoalMl;

  UserProfile copyWith({int? dailyGoalMl}) {
    return UserProfile(
      gender: gender,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      activityLevel: activityLevel,
      climate: climate,
      wakeTime: wakeTime,
      sleepTime: sleepTime,
      goalType: goalType,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
    );
  }

  Map<String, dynamic> toJson() => {
    'gender': gender,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'age': age,
    'activityLevel': activityLevel.name,
    'climate': climate.name,
    'wakeTime': _timeToJson(wakeTime),
    'sleepTime': _timeToJson(sleepTime),
    'goalType': goalType.name,
    'dailyGoalMl': dailyGoalMl,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      gender: json['gender'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toDouble(),
      age: json['age'] as int,
      activityLevel: ActivityLevel.values.byName(
        json['activityLevel'] as String,
      ),
      climate: Climate.values.byName(json['climate'] as String),
      wakeTime: _timeFromJson(json['wakeTime'] as String),
      sleepTime: _timeFromJson(json['sleepTime'] as String),
      goalType: GoalType.values.byName(json['goalType'] as String),
      dailyGoalMl: json['dailyGoalMl'] as int,
    );
  }
}

class IntakeEntry {
  const IntakeEntry({
    required this.id,
    required this.createdAt,
    required this.amountMl,
    required this.drink,
  });

  final String id;
  final DateTime createdAt;
  final int amountMl;
  final DrinkOption drink;

  int get effectiveMl => (amountMl * drink.multiplier).round();

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'amountMl': amountMl,
    'drink': drink.toJson(),
  };

  factory IntakeEntry.fromJson(Map<String, dynamic> json) {
    final legacyKind = json['drinkKind'];
    return IntakeEntry(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      amountMl: json['amountMl'] as int,
      drink: legacyKind == null
          ? DrinkOption.fromJson(json['drink'] as Map<String, dynamic>)
          : DrinkKind.values.byName(legacyKind as String).option,
    );
  }
}

class ReminderSettings {
  const ReminderSettings({
    this.enabled = true,
    this.weekendsEnabled = true,
    this.intervalMinutes = 90,
    this.adaptive = true,
    this.quietStart,
    this.quietEnd,
    this.sound = 'Gentle ripple',
    this.vibration = true,
  });

  final bool enabled;
  final bool weekendsEnabled;
  final int intervalMinutes;
  final bool adaptive;
  final TimeOfDay? quietStart;
  final TimeOfDay? quietEnd;
  final String sound;
  final bool vibration;

  ReminderSettings copyWith({
    bool? enabled,
    bool? weekendsEnabled,
    int? intervalMinutes,
    bool? adaptive,
    TimeOfDay? quietStart,
    TimeOfDay? quietEnd,
    String? sound,
    bool? vibration,
    bool clearQuietWindow = false,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      weekendsEnabled: weekendsEnabled ?? this.weekendsEnabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      adaptive: adaptive ?? this.adaptive,
      quietStart: clearQuietWindow ? null : quietStart ?? this.quietStart,
      quietEnd: clearQuietWindow ? null : quietEnd ?? this.quietEnd,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'weekendsEnabled': weekendsEnabled,
    'intervalMinutes': intervalMinutes,
    'adaptive': adaptive,
    'quietStart': quietStart == null ? null : _timeToJson(quietStart!),
    'quietEnd': quietEnd == null ? null : _timeToJson(quietEnd!),
    'sound': sound,
    'vibration': vibration,
  };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    return ReminderSettings(
      enabled: json['enabled'] as bool? ?? true,
      weekendsEnabled: json['weekendsEnabled'] as bool? ?? true,
      intervalMinutes: json['intervalMinutes'] as int? ?? 90,
      adaptive: json['adaptive'] as bool? ?? true,
      quietStart: json['quietStart'] == null
          ? null
          : _timeFromJson(json['quietStart'] as String),
      quietEnd: json['quietEnd'] == null
          ? null
          : _timeFromJson(json['quietEnd'] as String),
      sound: json['sound'] as String? ?? 'Gentle ripple',
      vibration: json['vibration'] as bool? ?? true,
    );
  }
}

class AdSettings {
  const AdSettings({
    this.consentComplete = false,
    this.rewardedAdFreeUntil,
    this.lastInterstitialAt,
    this.bannerImpressions = 0,
  });

  final bool consentComplete;
  final DateTime? rewardedAdFreeUntil;
  final DateTime? lastInterstitialAt;
  final int bannerImpressions;

  bool get isRewardAdFreeActive {
    final until = rewardedAdFreeUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  AdSettings copyWith({
    bool? consentComplete,
    DateTime? rewardedAdFreeUntil,
    DateTime? lastInterstitialAt,
    int? bannerImpressions,
  }) {
    return AdSettings(
      consentComplete: consentComplete ?? this.consentComplete,
      rewardedAdFreeUntil: rewardedAdFreeUntil ?? this.rewardedAdFreeUntil,
      lastInterstitialAt: lastInterstitialAt ?? this.lastInterstitialAt,
      bannerImpressions: bannerImpressions ?? this.bannerImpressions,
    );
  }

  Map<String, dynamic> toJson() => {
    'consentComplete': consentComplete,
    'rewardedAdFreeUntil': rewardedAdFreeUntil?.toIso8601String(),
    'lastInterstitialAt': lastInterstitialAt?.toIso8601String(),
    'bannerImpressions': bannerImpressions,
  };

  factory AdSettings.fromJson(Map<String, dynamic> json) {
    return AdSettings(
      consentComplete: json['consentComplete'] as bool? ?? false,
      rewardedAdFreeUntil: _dateFromJson(json['rewardedAdFreeUntil']),
      lastInterstitialAt: _dateFromJson(json['lastInterstitialAt']),
      bannerImpressions: json['bannerImpressions'] as int? ?? 0,
    );
  }
}

class AppSettings {
  const AppSettings({
    this.profile,
    this.unitSystem = UnitSystem.ml,
    this.themeMode = ThemeMode.system,
    this.accent = const Color(0xFF00A8A8),
    this.isPro = false,
    this.reminders = const ReminderSettings(),
    this.ads = const AdSettings(),
    this.mascotName = 'Drip',
    this.weather,
    this.weatherFetchState = WeatherFetchState.idle,
  });

  final UserProfile? profile;
  final UnitSystem unitSystem;
  final ThemeMode themeMode;
  final Color accent;
  final bool isPro;
  final ReminderSettings reminders;
  final AdSettings ads;
  final String mascotName;
  final WeatherData? weather;
  final WeatherFetchState weatherFetchState;

  bool get shouldShowAds => !isPro && !ads.isRewardAdFreeActive;

  AppSettings copyWith({
    UserProfile? profile,
    UnitSystem? unitSystem,
    ThemeMode? themeMode,
    Color? accent,
    bool? isPro,
    ReminderSettings? reminders,
    AdSettings? ads,
    String? mascotName,
    WeatherData? weather,
    WeatherFetchState? weatherFetchState,
    bool clearProfile = false,
    bool clearWeather = false,
  }) {
    return AppSettings(
      profile: clearProfile ? null : profile ?? this.profile,
      unitSystem: unitSystem ?? this.unitSystem,
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      isPro: isPro ?? this.isPro,
      reminders: reminders ?? this.reminders,
      ads: ads ?? this.ads,
      mascotName: mascotName ?? this.mascotName,
      weather: clearWeather ? null : weather ?? this.weather,
      weatherFetchState: weatherFetchState ?? this.weatherFetchState,
    );
  }

  Map<String, dynamic> toJson() => {
    'profile': profile?.toJson(),
    'unitSystem': unitSystem.name,
    'themeMode': themeMode.name,
    'accent': accent.toARGB32(),
    'isPro': isPro,
    'reminders': reminders.toJson(),
    'ads': ads.toJson(),
    'mascotName': mascotName,
    'weather': weather?.toJson(),
    'weatherFetchState': weatherFetchState.name,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final weatherJson = json['weather'] as Map<String, dynamic>?;
    return AppSettings(
      profile: json['profile'] == null
          ? null
          : UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
      unitSystem: UnitSystem.values.byName(json['unitSystem'] as String),
      themeMode: ThemeMode.values.byName(json['themeMode'] as String),
      accent: Color(json['accent'] as int),
      isPro: json['isPro'] as bool? ?? false,
      reminders: json['reminders'] == null
          ? const ReminderSettings()
          : ReminderSettings.fromJson(
              json['reminders'] as Map<String, dynamic>,
            ),
      ads: json['ads'] == null
          ? const AdSettings()
          : AdSettings.fromJson(json['ads'] as Map<String, dynamic>),
      mascotName: json['mascotName'] as String? ?? 'Drip',
      weather: weatherJson != null ? WeatherData.fromJson(weatherJson) : null,
      weatherFetchState: WeatherFetchState.values.byName(
        json['weatherFetchState'] as String? ?? 'idle',
      ),
    );
  }
}

class HydroState {
  const HydroState({
    this.settings = const AppSettings(),
    this.entries = const [],
    this.customDrinks = const [],
    this.isLoading = true,
  });

  final AppSettings settings;
  final List<IntakeEntry> entries;
  final List<DrinkOption> customDrinks;
  final bool isLoading;

  bool get hasCompletedOnboarding => settings.profile != null;

  List<DrinkOption> get drinkOptions => [
    ...DrinkKind.values.map((kind) => kind.option),
    ...customDrinks,
  ];

  int get todayEffectiveMl {
    final now = DateTime.now();
    return entries
        .where((entry) => _isSameDay(entry.createdAt, now))
        .fold(0, (total, entry) => total + entry.effectiveMl);
  }

  int get todayRawMl {
    final now = DateTime.now();
    return entries
        .where((entry) => _isSameDay(entry.createdAt, now))
        .fold(0, (total, entry) => total + entry.amountMl);
  }

  double get todayProgress {
    final goal = weatherAdjustedGoalMl;
    return (todayEffectiveMl / goal).clamp(0, 1);
  }

  /// Base daily goal from user profile.
  int get baseGoalMl => settings.profile?.dailyGoalMl ?? 2500;

  /// Goal adjusted upward/downward by current temperature.
  int get weatherAdjustedGoalMl {
    final base = baseGoalMl;
    final boost = settings.weather?.temperatureBoostMl ?? 0;
    return (base + boost).clamp(1500, 5000);
  }

  MascotMood get mascotMood {
    final progress = todayProgress;
    if (progress >= 1) return MascotMood.celebrating;
    if (progress >= .65) return MascotMood.cheering;
    if (progress >= .25) return MascotMood.steady;
    return MascotMood.sleepy;
  }

  List<IntakeEntry> get todayEntries {
    final now = DateTime.now();
    return entries.where((entry) => _isSameDay(entry.createdAt, now)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  HydroState copyWith({
    AppSettings? settings,
    List<IntakeEntry>? entries,
    List<DrinkOption>? customDrinks,
    bool? isLoading,
  }) {
    return HydroState(
      settings: settings ?? this.settings,
      entries: entries ?? this.entries,
      customDrinks: customDrinks ?? this.customDrinks,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  String encode() => jsonEncode({
    'settings': settings.toJson(),
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'customDrinks': customDrinks.map((drink) => drink.toJson()).toList(),
  });

  factory HydroState.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return HydroState(
      settings: AppSettings.fromJson(json['settings'] as Map<String, dynamic>),
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((entry) => IntakeEntry.fromJson(entry as Map<String, dynamic>))
          .toList(),
      customDrinks: (json['customDrinks'] as List<dynamic>? ?? [])
          .map((drink) => DrinkOption.fromJson(drink as Map<String, dynamic>))
          .toList(),
      isLoading: false,
    );
  }
}

String mascotEmoji(MascotMood mood) {
  return switch (mood) {
    MascotMood.sleepy => '💧',
    MascotMood.steady => '💦',
    MascotMood.cheering => '🌊',
    MascotMood.celebrating => '🏆',
  };
}

String _timeToJson(TimeOfDay time) => '${time.hour}:${time.minute}';

TimeOfDay _timeFromJson(String source) {
  final parts = source.split(':').map(int.parse).toList();
  return TimeOfDay(hour: parts[0], minute: parts[1]);
}

DateTime? _dateFromJson(Object? source) {
  if (source == null) return null;
  return DateTime.tryParse(source as String);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _isSameDay(DateTime a, DateTime b) => isSameDay(a, b);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hydro_state.dart';
import '../models/weather_model.dart';
import 'location_service.dart';
import 'reminder_service.dart';
import 'weather_service.dart';

final hydroControllerProvider = NotifierProvider<HydroController, HydroState>(
  HydroController.new,
);

class HydroController extends Notifier<HydroState> {
  static const _storageKey = 'hydroflow_state_v1';

  @override
  HydroState build() {
    _load();
    return const HydroState();
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    state = state.copyWith(
      settings: state.settings.copyWith(profile: profile),
      isLoading: false,
    );
    await _save();
  }

  Future<void> addIntake(int amountMl, DrinkOption drink) async {
    final entry = IntakeEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      amountMl: amountMl,
      drink: drink,
    );
    state = state.copyWith(entries: [entry, ...state.entries]);
    await _save();
  }

  Future<void> addCustomDrink(DrinkOption drink) async {
    final freeLimitReached =
        !state.settings.isPro && state.customDrinks.length >= 2;
    if (freeLimitReached) return;
    state = state.copyWith(customDrinks: [drink, ...state.customDrinks]);
    await _save();
  }

  Future<void> removeCustomDrink(String id) async {
    state = state.copyWith(
      customDrinks: state.customDrinks
          .where((drink) => drink.id != id)
          .toList(),
    );
    await _save();
  }

  Future<void> removeEntry(String id) async {
    state = state.copyWith(
      entries: state.entries.where((entry) => entry.id != id).toList(),
    );
    await _save();
  }

  Future<void> updateUnit(UnitSystem unitSystem) async {
    state = state.copyWith(
      settings: state.settings.copyWith(unitSystem: unitSystem),
    );
    await _save();
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(
      settings: state.settings.copyWith(themeMode: themeMode),
    );
    await _save();
  }

  Future<void> updateAccent(Color accent) async {
    state = state.copyWith(settings: state.settings.copyWith(accent: accent));
    await _save();
  }

  Future<void> updateReminderSettings(ReminderSettings reminders) async {
    state = state.copyWith(
      settings: state.settings.copyWith(reminders: reminders),
    );
    await _save();
  }

  Future<void> completeAdConsent() async {
    state = state.copyWith(
      settings: state.settings.copyWith(
        ads: state.settings.ads.copyWith(consentComplete: true),
      ),
    );
    await _save();
  }

  Future<void> grantRewardedAdFreeHour() async {
    state = state.copyWith(
      settings: state.settings.copyWith(
        ads: state.settings.ads.copyWith(
          rewardedAdFreeUntil: DateTime.now().add(const Duration(hours: 1)),
        ),
      ),
    );
    await _save();
  }

  Future<void> showInterstitialCheckpoint() async {
    final now = DateTime.now();
    final last = state.settings.ads.lastInterstitialAt;
    if (last != null && now.difference(last).inMinutes < 4) return;
    state = state.copyWith(
      settings: state.settings.copyWith(
        ads: state.settings.ads.copyWith(lastInterstitialAt: now),
      ),
    );
    await _save();
  }

  Future<void> toggleProPreview() async {
    state = state.copyWith(
      settings: state.settings.copyWith(isPro: !state.settings.isPro),
    );
    await _save();
  }

  Future<void> updateMascotName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      settings: state.settings.copyWith(mascotName: trimmed),
    );
    await _save();
  }

  Future<void> resetProfile() async {
    state = state.copyWith(
      settings: state.settings.copyWith(clearProfile: true),
    );
    await _save();
  }

  /// Orchestrates location permission → position → weather fetch.
  Future<void> fetchWeatherAndLocation() async {
    const locationService = LocationService();
    const weatherService = WeatherService();

    // Already loading — skip
    if (state.settings.weatherFetchState == WeatherFetchState.loading) return;

    // Use cached data if still fresh
    final cached = state.settings.weather;
    if (cached != null && cached.isFresh) return;

    state = state.copyWith(
      settings: state.settings.copyWith(
        weatherFetchState: WeatherFetchState.loading,
      ),
    );

    try {
      // Check location service enabled
      final enabled = await locationService.isServiceEnabled();
      if (!enabled) {
        state = state.copyWith(
          settings: state.settings.copyWith(
            weatherFetchState: WeatherFetchState.denied,
          ),
        );
        return;
      }

      // Check / request permission
      var permission = await locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await locationService.requestPermission();
      }

      if (!locationService.isGranted(permission)) {
        state = state.copyWith(
          settings: state.settings.copyWith(
            weatherFetchState: WeatherFetchState.denied,
          ),
        );
        await _save();
        return;
      }

      final position = await locationService.getCurrentPosition();
      if (position == null) {
        state = state.copyWith(
          settings: state.settings.copyWith(
            weatherFetchState: WeatherFetchState.error,
          ),
        );
        return;
      }

      final weather = await weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );

      if (weather == null) {
        state = state.copyWith(
          settings: state.settings.copyWith(
            weatherFetchState: WeatherFetchState.error,
          ),
        );
        return;
      }

      state = state.copyWith(
        settings: state.settings.copyWith(
          weather: weather,
          weatherFetchState: WeatherFetchState.success,
          // Re-sync reminder interval to temperature
          reminders: state.settings.reminders.copyWith(
            intervalMinutes: weather.reminderIntervalMinutes,
          ),
        ),
      );

      // Re-schedule notifications with new interval
      final profile = state.settings.profile;
      if (profile != null) {
        await const ReminderService().requestPermissionsAndSchedule(
          profile: profile,
          settings: state.settings.reminders,
          weather: weather,
        );
      }

      await _save();
    } catch (e) {
      state = state.copyWith(
        settings: state.settings.copyWith(
          weatherFetchState: WeatherFetchState.error,
        ),
      );
    }
  }

  Future<void> dismissLocationPrompt() async {
    state = state.copyWith(
      settings: state.settings.copyWith(
        weatherFetchState: WeatherFetchState.denied,
      ),
    );
    await _save();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = HydroState.decode(raw);
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      state.copyWith(isLoading: false).encode(),
    );
  }
}

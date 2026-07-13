import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/hydro_state.dart';
import '../../core/models/weather_model.dart';
import '../../core/services/drink_advice_service.dart';
import '../../core/services/hydro_controller.dart';
import 'drink_advice_sheet.dart';

/// Dashboard weather insight card shown when location is granted.
class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key, required this.weather});

  final WeatherData weather;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydroControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final tempAdvisory = _tempAdvisory(weather.temperatureC);
    final adjustedGoal = state.weatherAdjustedGoalMl;
    final baseGoal = state.baseGoalMl;
    final boost = adjustedGoal - baseGoal;
    final splitCount = _splitCount(state.settings.profile, weather);

    final allDrinks = state.drinkOptions;
    final adviceService = const DrinkAdviceService();
    final allAdvice = adviceService.adviceForAll(allDrinks, weather.temperatureC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top weather strip ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: tempAdvisory.gradientColors,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    weather.conditionEmoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather.city,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                        Text(
                          '${weather.temperatureLabel}  ·  ${weather.conditionLabel}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                        ),
                        if (weather.feelsLikeC != weather.temperatureC)
                          Text(
                            'Feels like ${weather.feelsLikeC.round()}°C',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                          ),
                      ],
                    ),
                  ),
                  // Refresh button
                  IconButton(
                    onPressed: () => ref
                        .read(hydroControllerProvider.notifier)
                        .fetchWeatherAndLocation(),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    tooltip: 'Refresh weather',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Goal row ──────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white),
                          children: [
                            TextSpan(
                              text: 'At ${weather.temperatureLabel}, your goal is ',
                            ),
                            TextSpan(
                              text: '$adjustedGoal ml',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (boost != 0)
                              TextSpan(
                                text: boost > 0
                                    ? ' (+$boost ml for heat)'
                                    : ' ($boost ml cool adjustment)',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // ── Splits row ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black.withValues(alpha: 0.14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white),
                          children: [
                            TextSpan(
                              text: '$splitCount hydration reminder${splitCount == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(
                              text: ' scheduled today  ·  every '
                                  '${weather.reminderIntervalMinutes} min',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 450.ms)
            .slideY(begin: -0.04, end: 0, duration: 400.ms),
        const SizedBox(height: 16),
        // ── Drink advice header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'DRINK ADVICE AT ${weather.temperatureLabel}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        // ── Horizontal drink advice scroll ───────────────────────────────
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: allAdvice.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final advice = allAdvice[index];
              return _DrinkAdviceTile(advice: advice);
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Tap any drink for full advice',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  int _splitCount(UserProfile? profile, WeatherData weather) {
    if (profile == null) return 0;
    final wake = profile.wakeTime.hour * 60 + profile.wakeTime.minute;
    final sleep = profile.sleepTime.hour * 60 + profile.sleepTime.minute;
    final wakingMinutes =
        sleep > wake ? sleep - wake : (1440 - wake) + sleep;
    return (wakingMinutes / weather.reminderIntervalMinutes).floor();
  }
}

// ── Temperature advisory helper ──────────────────────────────────────────────

class _TempAdvisory {
  const _TempAdvisory({
    required this.gradientColors,
  });
  final List<Color> gradientColors;
}

_TempAdvisory _tempAdvisory(double t) {
  if (t >= 38) {
    return const _TempAdvisory(gradientColors: [
      Color(0xFFb91c1c),
      Color(0xFF7f1d1d),
    ]);
  }
  if (t >= 30) {
    return const _TempAdvisory(gradientColors: [
      Color(0xFFea580c),
      Color(0xFFc2410c),
    ]);
  }
  if (t >= 20) {
    return const _TempAdvisory(gradientColors: [
      Color(0xFF0284c7),
      Color(0xFF0369a1),
    ]);
  }
  return const _TempAdvisory(gradientColors: [
    Color(0xFF0891b2),
    Color(0xFF164e63),
  ]);
}

// ── Individual drink tile ────────────────────────────────────────────────────

class _DrinkAdviceTile extends StatelessWidget {
  const _DrinkAdviceTile({required this.advice});

  final DrinkAdvice advice;

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(advice.level);
    return GestureDetector(
      onTap: () => showDrinkAdviceSheet(context, advice),
      child: Container(
        width: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.4),
          border: Border.all(
            color: levelColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: advice.drink.color.withValues(alpha: 0.12),
                  ),
                  child: Center(
                    child: Text(
                      advice.drink.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: levelColor,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              advice.drink.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              advice.recommendedMl > 0
                  ? '${advice.recommendedMl}ml'
                  : 'Avoid',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(AdviceLevel level) => switch (level) {
        AdviceLevel.great => const Color(0xFF22c55e),
        AdviceLevel.good => const Color(0xFFca8a04),
        AdviceLevel.caution => const Color(0xFFea580c),
        AdviceLevel.avoid => const Color(0xFFef4444),
      };
}

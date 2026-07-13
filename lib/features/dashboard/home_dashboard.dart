import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/models/hydro_state.dart';
import '../../core/models/weather_model.dart';
import '../../core/services/hydro_controller.dart';
import 'location_permission_card.dart';
import 'weather_card.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  DrinkOption _selectedDrink = DrinkKind.water.option;

  @override
  void initState() {
    super.initState();
    // Kick off weather fetch after first frame (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(hydroControllerProvider);
      final fetchState = state.settings.weatherFetchState;
      // Auto-fetch if idle or if cached data is stale
      if (fetchState == WeatherFetchState.idle ||
          (state.settings.weather != null &&
              !state.settings.weather!.isFresh)) {
        ref.read(hydroControllerProvider.notifier).fetchWeatherAndLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hydroControllerProvider);
    final progress = state.todayProgress;
    final adjustedGoal = state.weatherAdjustedGoalMl;
    final copy = _motivationalCopy(progress);
    final weather = state.settings.weather;
    final fetchState = state.settings.weatherFetchState;
    final showPermissionCard = fetchState == WeatherFetchState.idle;
    if (!state.drinkOptions.any((drink) => drink.id == _selectedDrink.id)) {
      _selectedDrink = DrinkKind.water.option;
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HydroFlow',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              Text(
                                copy,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        _StreakBadge(entries: state.entries),
                      ],
                    ),
                    const SizedBox(height: 28),
                    // ── Location permission card ─────────────────────────────
                    if (showPermissionCard) const LocationPermissionCard(),
                    // ── Weather card (when data is available) ────────────────
                    if (weather != null) WeatherCard(weather: weather),
                    const SizedBox(height: 28),
                    _MascotHero(
                      mascotName: state.settings.mascotName,
                      mood: state.mascotMood,
                      progress: progress,
                      copy: copy,
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: _WaveProgress(
                        progress: progress,
                        intake: _formatAmount(
                          state.todayEffectiveMl,
                          state.settings.unitSystem,
                        ),
                        goal: _formatAmount(
                          adjustedGoal,
                          state.settings.unitSystem,
                        ),
                        isWeatherAdjusted: weather != null,
                      )
                          .animate()
                          .fadeIn(duration: 450.ms)
                          .scale(begin: const Offset(.96, .96)),
                    ),
                    const SizedBox(height: 28),
                    _DrinkPicker(
                      drinks: state.drinkOptions,
                      selected: _selectedDrink,
                      onSelected: (drink) =>
                          setState(() => _selectedDrink = drink),
                    ),
                    const SizedBox(height: 20),
                    _QuickAdds(
                      unitSystem: state.settings.unitSystem,
                      onAdd: (amount) => _add(amount, _selectedDrink),
                    ),
                    const SizedBox(height: 28),
                    _TodayEntries(entries: state.todayEntries),
                    const SizedBox(height: 20),
                    if (state.settings.shouldShowAds)
                      _AdBanner(
                        onReward: () => ref
                            .read(hydroControllerProvider.notifier)
                            .grantRewardedAdFreeHour(),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCustomAmountSheet,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Custom'),
      ),
    );
  }

  Future<void> _add(int amountMl, DrinkOption drink) async {
    HapticFeedback.selectionClick();
    await ref.read(hydroControllerProvider.notifier).addIntake(amountMl, drink);
  }

  Future<void> _showCustomAmountSheet() async {
    final controller = TextEditingController(text: '300');
    final amount = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Custom amount',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  suffixText: 'ml',
                  hintText: 'Amount',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(context, int.tryParse(controller.text)),
                child: const Text('Add drink'),
              ),
            ],
          ),
        );
      },
    );
    if (amount != null && amount > 0) {
      await _add(amount, _selectedDrink);
    }
  }
}

class _MascotHero extends StatelessWidget {
  const _MascotHero({
    required this.mascotName,
    required this.mood,
    required this.progress,
    required this.copy,
  });

  final String mascotName;
  final MascotMood mood;
  final double progress;
  final String copy;

  @override
  Widget build(BuildContext context) {
    final message = switch (mood) {
      MascotMood.sleepy => 'I am warming up. First sip?',
      MascotMood.steady => 'Nice rhythm. Keep it light.',
      MascotMood.cheering => 'Almost there. The wave is rising.',
      MascotMood.celebrating => 'Goal complete. I am doing a tiny splash dance.',
    };

    return Row(
      children: [
        Text(mascotEmoji(mood), style: const TextStyle(fontSize: 48))
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(
              begin: const Offset(.92, .92),
              end: const Offset(1.04, 1.04),
              duration: 1500.ms,
            ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$mascotName says:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WaveProgress extends StatelessWidget {
  const _WaveProgress({
    required this.progress,
    required this.intake,
    required this.goal,
    this.isWeatherAdjusted = false,
  });

  final double progress;
  final String intake;
  final String goal;
  final bool isWeatherAdjusted;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return SizedBox(
          width: 250,
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(250),
                painter: _WavePainter(
                  progress: value,
                  color: Theme.of(context).colorScheme.primary,
                  secondary: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$intake of $goal',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (isWeatherAdjusted) ...
                    [
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thermostat_rounded,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'weather adjusted',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.progress,
    required this.color,
    required this.secondary,
  });

  final double progress;
  final Color color;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;

    // Background soft radial gradient glow
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: .12),
          secondary.withValues(alpha: .04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, bgPaint);

    final circle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - 6));

    canvas.save();
    canvas.clipPath(circle);

    // Wave drawing
    final waterTop = size.height * (1 - progress);

    // Background wave (Secondary)
    final backPath = Path()..moveTo(0, waterTop);
    for (var x = 0.0; x <= size.width; x += 4) {
      final y = waterTop +
          math.sin((x / size.width * math.pi * 2) - progress * 4) * 8;
      backPath.lineTo(x, y);
    }
    backPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final backWater = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          secondary.withValues(alpha: .3),
          color.withValues(alpha: .5),
        ],
      ).createShader(rect);
    canvas.drawPath(backPath, backWater);

    // Foreground wave (Primary)
    final forePath = Path()..moveTo(0, waterTop);
    for (var x = 0.0; x <= size.width; x += 4) {
      final y = waterTop +
          math.sin((x / size.width * math.pi * 2) + progress * 6) * 6;
      forePath.lineTo(x, y);
    }
    forePath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final foreWater = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: .9),
          color,
        ],
      ).createShader(rect);
    canvas.drawPath(forePath, foreWater);

    canvas.restore();

    // Outer track glow ring
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: .1);
    canvas.drawCircle(center, radius - 2, trackPaint);

    // Active progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: [
            secondary.withValues(alpha: 0.2),
            color,
            secondary,
            color,
          ],
          stops: const [0.0, 0.4, 0.8, 1.0],
        ).createShader(rect);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return progress != oldDelegate.progress ||
        color != oldDelegate.color ||
        secondary != oldDelegate.secondary;
  }
}

class _DrinkPicker extends StatelessWidget {
  const _DrinkPicker({
    required this.drinks,
    required this.selected,
    required this.onSelected,
  });

  final List<DrinkOption> drinks;
  final DrinkOption selected;
  final ValueChanged<DrinkOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: drinks.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final drink = drinks[index];
          final isSelected = drink.id == selected.id;
          return GestureDetector(
            onTap: () => onSelected(drink),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? drink.color.withValues(alpha: .18)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: .4),
                    border: Border.all(
                      color: isSelected ? drink.color : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: drink.color.withValues(alpha: .25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      drink.emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  drink.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickAdds extends StatelessWidget {
  const _QuickAdds({required this.unitSystem, required this.onAdd});

  final UnitSystem unitSystem;
  final ValueChanged<int> onAdd;

  @override
  Widget build(BuildContext context) {
    const amounts = [100, 250, 500, 1000];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: amounts.map((amount) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              onPressed: () => onAdd(amount),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const StadiumBorder(),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .25),
                  width: 1.5,
                ),
              ),
              child: Text(
                '+${_formatAmount(amount, unitSystem).replaceAll(' ', '')}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TodayEntries extends ConsumerWidget {
  const _TodayEntries({required this.entries});

  final List<IntakeEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.opacity_rounded,
                size: 32,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.35),
              ),
              const SizedBox(height: 8),
              Text(
                'No drinks logged yet',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Start with one small glass. Tiny loops count.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(
            'TODAY\'S LOGS',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.take(5).length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3),
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.drink.color.withValues(alpha: .12),
                ),
                child: Center(
                  child: Text(
                    entry.drink.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              title: Text(
                entry.drink.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${entry.effectiveMl} ml effective hydration',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              trailing: IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => ref
                    .read(hydroControllerProvider.notifier)
                    .removeEntry(entry.id),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AdBanner extends StatefulWidget {
  const _AdBanner({required this.onReward});

  final VoidCallback onReward;

  @override
  State<_AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<_AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    if (kIsWeb) return;

    final adUnitId = defaultTargetPlatform == TargetPlatform.android
        ? 'ca-app-pub-1969259760721536/6519683605'
        : 'ca-app-pub-3940256099942544/2934735716';

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoaded && _bannerAd != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onReward,
              icon: const Icon(Icons.star_rounded, size: 14),
              label: const Text(
                'Remove ads for 1 hour',
                style: TextStyle(fontSize: 11),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surfaceContainerHighest.withValues(alpha: .4),
      ),
      child: Row(
        children: [
          Icon(
            Icons.ads_click_rounded,
            color: scheme.primary.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ad space reserved. Remove ads for 1 hr.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          TextButton(
            onPressed: widget.onReward,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Watch Ad'),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge({required this.entries});

  final List<IntakeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final streak = _streakDays(entries);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak d',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

String _motivationalCopy(double progress) {
  final hour = DateTime.now().hour;
  if (progress >= 1) return 'Goal complete. Beautifully hydrated.';
  if (hour < 11) return 'A calm start makes the rest easier.';
  if (hour < 17) return 'A gentle top-up keeps the day moving.';
  return 'Wind down with a steady finish.';
}

String _formatAmount(int ml, UnitSystem unitSystem) {
  if (unitSystem == UnitSystem.ml) return '$ml ml';
  final oz = ml / 29.5735;
  return '${oz.round()} oz';
}

int _streakDays(List<IntakeEntry> entries) {
  if (entries.isEmpty) return 0;
  final days = entries
      .map(
        (entry) => DateTime(
          entry.createdAt.year,
          entry.createdAt.month,
          entry.createdAt.day,
        ),
      )
      .toSet();
  var cursor = DateTime.now();
  var streak = 0;
  while (days.contains(DateTime(cursor.year, cursor.month, cursor.day))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

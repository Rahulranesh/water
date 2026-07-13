import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(hydroControllerProvider);
      final fetchState = state.settings.weatherFetchState;
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

    return CupertinoPageScaffold(
      child: Material(
        color: Colors.transparent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('HydroFlow'),
              border: null,
              backgroundColor: CupertinoTheme.of(context)
                  .barBackgroundColor
                  .withValues(alpha: 0.82),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showCustomAmountSheet,
                child: const Icon(CupertinoIcons.add, size: 24),
              ),
            ),
            SliverSafeArea(
              top: false,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                copy,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CupertinoDynamicColor.resolve(
                                    CupertinoColors.secondaryLabel,
                                    context,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _StreakBadge(entries: state.entries),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 24),
                        // ── Location permission card ─────────────────────────────
                        if (showPermissionCard) const LocationPermissionCard(),
                        // ── Weather card (when data is available) ────────────────
                        if (weather != null) WeatherCard(weather: weather),
                        const SizedBox(height: 16),
                        _MascotHero(
                          mascotName: state.settings.mascotName,
                          mood: state.mascotMood,
                          progress: progress,
                          copy: copy,
                        ),
                        const SizedBox(height: 32),
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
                              .fadeIn(duration: 500.ms)
                              .scale(begin: const Offset(.95, .95)),
                        ),
                        const SizedBox(height: 36),
                        _SectionHeader(title: 'CHOOSE BEVERAGE'),
                        _DrinkPicker(
                          drinks: state.drinkOptions,
                          selected: _selectedDrink,
                          onSelected: (drink) =>
                              setState(() => _selectedDrink = drink),
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(title: 'QUICK LOG'),
                        _QuickAdds(
                          unitSystem: state.settings.unitSystem,
                          onAdd: (amount) => _add(amount, _selectedDrink),
                        ),
                        const SizedBox(height: 36),
                        _TodayEntries(entries: state.todayEntries),
                        const SizedBox(height: 24),
                        if (state.settings.shouldShowAds)
                          _AdBanner(
                            onReward: () => ref
                                .read(hydroControllerProvider.notifier)
                                .grantRewardedAdFreeHour(),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(int amountMl, DrinkOption drink) async {
    HapticFeedback.selectionClick();
    await ref.read(hydroControllerProvider.notifier).addIntake(amountMl, drink);
  }

  Future<void> _showCustomAmountSheet() async {
    final controller = TextEditingController(text: '300');
    final amount = await showCupertinoDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Custom Hydration'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Material(
              color: Colors.transparent,
              child: CupertinoTextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Icon(
                    CupertinoIcons.drop_fill,
                    color: CupertinoColors.systemBlue,
                    size: 18,
                  ),
                ),
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Text('ml', style: TextStyle(color: CupertinoColors.secondaryLabel, fontWeight: FontWeight.bold)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGroupedBackground,
                    context,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              isDestructiveAction: true,
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () =>
                  Navigator.pop(context, int.tryParse(controller.text)),
              isDefaultAction: true,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (amount != null && amount > 0) {
      await _add(amount, _selectedDrink);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.secondaryLabel,
            context,
          ),
        ),
      ),
    );
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

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(mascotEmoji(mood), style: const TextStyle(fontSize: 44))
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0x20FFFFFF)
                        : const Color(0x0F000000),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          width: 230,
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(230),
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
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$intake of $goal',
                    style: TextStyle(
                      color: CupertinoDynamicColor.resolve(
                        CupertinoColors.secondaryLabel,
                        context,
                      ),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  if (isWeatherAdjusted) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.thermometer,
                          size: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'weather adjusted',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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

    final waterTop = size.height * (1 - progress);

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

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: .1);
    canvas.drawCircle(center, radius - 2, trackPaint);

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
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
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
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutQuint,
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? drink.color.withValues(alpha: .18)
                        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                    border: Border.all(
                      color: isSelected ? drink.color : Colors.transparent,
                      width: 2.2,
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? CupertinoDynamicColor.resolve(
                            CupertinoColors.label,
                            context,
                          )
                        : CupertinoDynamicColor.resolve(
                            CupertinoColors.secondaryLabel,
                            context,
                          ),
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
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: amounts.map((amount) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => onAdd(amount),
              child: Container(
                alignment: Alignment.center,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: .25),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  '+${_formatAmount(amount, unitSystem).replaceAll(' ', '')}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.drop,
              size: 32,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.35),
            ),
            const SizedBox(height: 8),
            const Text(
              'No drinks logged yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Start with one small glass. Tiny loops count.',
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            'TODAY\'S LOGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: CupertinoDynamicColor.resolve(
                CupertinoColors.secondaryLabel,
                context,
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.take(5).length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0D000000),
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.drink.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.effectiveMl} ml effective hydration',
                            style: TextStyle(
                              color: CupertinoDynamicColor.resolve(
                                CupertinoColors.secondaryLabel,
                                context,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.xmark_circle,
                        size: 22,
                        color: Color(0xFF8E8E93),
                      ),
                      onPressed: () => ref
                          .read(hydroControllerProvider.notifier)
                          .removeEntry(entry.id),
                    ),
                  ],
                ),
              );
            },
          ),
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
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

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
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: widget.onReward,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.star_fill, size: 12, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Remove ads for 1 hour',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.device_phone_portrait,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ad space reserved. Remove ads for 1 hr.',
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
                fontSize: 12,
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            onPressed: widget.onReward,
            child: Text(
              'Watch Ad',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.72),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.flame_fill,
            size: 15,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$streak d',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
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

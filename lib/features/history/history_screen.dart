import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/hydro_state.dart';
import '../../core/services/hydro_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydroControllerProvider);
    final days = _lastSevenDays(state.entries);
    final goal = state.settings.profile?.dailyGoalMl ?? 2500;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return CupertinoPageScaffold(
      child: Material(
        color: Colors.transparent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('History'),
              border: null,
              backgroundColor: CupertinoTheme.of(context)
                  .barBackgroundColor
                  .withValues(alpha: 0.82),
            ),
            SliverSafeArea(
              top: false,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(title: '7-DAY HYDRATION'),
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 180,
                              child: BarChart(
                                BarChartData(
                                  maxY: (goal * 1.25).toDouble(),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index < 0 || index >= days.length) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              DateFormat.E().format(days[index].date),
                                              style: TextStyle(
                                                color: CupertinoDynamicColor.resolve(
                                                  CupertinoColors.secondaryLabel,
                                                  context,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: [
                                    for (var i = 0; i < days.length; i++)
                                      BarChartGroupData(
                                        x: i,
                                        barRods: [
                                          BarChartRodData(
                                            toY: days[i].ml.toDouble(),
                                            width: 16,
                                            borderRadius: BorderRadius.circular(4),
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: days[i].ml >= goal
                                                  ? [
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withValues(alpha: 0.7),
                                                      Theme.of(context).colorScheme.primary,
                                                    ]
                                                  : [
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                          .withValues(alpha: 0.6),
                                                      Theme.of(context).colorScheme.secondary,
                                                    ],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                  extraLinesData: ExtraLinesData(
                                    horizontalLines: [
                                      HorizontalLine(
                                        y: goal.toDouble(),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.25),
                                        strokeWidth: 1.2,
                                        dashArray: [6, 4],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .scale(begin: const Offset(0.98, 1)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _Breakdown(entries: state.todayEntries),
                      const SizedBox(height: 32),
                      _BadgePanel(entries: state.entries),
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

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.entries});

  final List<IntakeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final byDrink = <String, (DrinkOption, int)>{};
    for (final entry in entries) {
      final current = byDrink[entry.drink.id];
      byDrink[entry.drink.id] = (
        entry.drink,
        (current?.$2 ?? 0) + entry.effectiveMl,
      );
    }

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'TODAY\'S BREAKDOWN'),
        if (byDrink.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'No drinks logged yet today.',
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondaryLabel,
                  context,
                ),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: byDrink.length,
              separatorBuilder: (context, index) => Container(
                height: 1,
                color: isDark ? const Color(0x1AFFFFFF) : const Color(0x0D000000),
              ),
              itemBuilder: (context, index) {
                final item = byDrink.values.elementAt(index);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.$1.color.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Text(
                            item.$1.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.$1.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        '${item.$2} ml',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 15,
                        ),
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

class _BadgePanel extends StatelessWidget {
  const _BadgePanel({required this.entries});

  final List<IntakeEntry> entries;

  @override
  Widget build(BuildContext context) {
    final loggedDays = entries
        .map(
          (entry) => DateTime(
            entry.createdAt.year,
            entry.createdAt.month,
            entry.createdAt.day,
          ),
        )
        .toSet()
        .length;
    final badges = [
      ('First Pour', loggedDays >= 1, CupertinoIcons.drop_fill, 'Log 1 drink'),
      (
        '7-Day Streak',
        loggedDays >= 7,
        CupertinoIcons.flame_fill,
        'Log 7 days'
      ),
      (
        'Hydration Hero',
        loggedDays >= 30,
        CupertinoIcons.heart_fill,
        'Log 30 days'
      ),
    ];

    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'BADGES & MILESTONES'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: badges.map((badge) {
            final unlocked = badge.$2;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: unlocked
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.62)
                    : (isDark ? const Color(0xFF2C2C2E) : Colors.white),
                border: Border.all(
                  color: unlocked
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.25)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    badge.$3,
                    size: 18,
                    color: unlocked
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF8E8E93),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        badge.$1,
                        style: TextStyle(
                          fontWeight:
                              unlocked ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                          color: unlocked
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                              : CupertinoDynamicColor.resolve(
                                  CupertinoColors.label,
                                  context,
                                ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge.$4,
                        style: TextStyle(
                          fontSize: 10,
                          color: unlocked
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer
                                  .withValues(alpha: 0.7)
                              : CupertinoDynamicColor.resolve(
                                  CupertinoColors.secondaryLabel,
                                  context,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

List<_DayTotal> _lastSevenDays(List<IntakeEntry> entries) {
  final today = DateTime.now();
  return List.generate(7, (index) {
    final date = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: 6 - index));
    final total = entries
        .where(
          (entry) =>
              entry.createdAt.year == date.year &&
              entry.createdAt.month == date.month &&
              entry.createdAt.day == date.day,
        )
        .fold(0, (sum, entry) => sum + entry.effectiveMl);
    return _DayTotal(date, total);
  });
}

class _DayTotal {
  const _DayTotal(this.date, this.ml);

  final DateTime date;
  final int ml;
}

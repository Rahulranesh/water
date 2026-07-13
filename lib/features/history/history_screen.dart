import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          Text(
            '7-DAY HYDRATION',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
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
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
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
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
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
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _Breakdown(entries: state.todayEntries),
          const SizedBox(height: 32),
          _BadgePanel(entries: state.entries),
          const SizedBox(height: 32),
        ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY\'S BREAKDOWN',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        if (byDrink.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Text(
              'No drinks logged yet today.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: byDrink.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final item = byDrink.values.elementAt(index);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: Container(
                  width: 42,
                  height: 42,
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
                title: Text(
                  item.$1.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  '${item.$2} ml',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              );
            },
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
      ('First Pour', loggedDays >= 1, Icons.water_drop_rounded, 'Log 1 drink'),
      (
        '7-Day Streak',
        loggedDays >= 7,
        Icons.local_fire_department_rounded,
        'Log 7 days'
      ),
      (
        'Hydration Hero',
        loggedDays >= 30,
        Icons.workspace_premium_rounded,
        'Log 30 days'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BADGES & MILESTONES',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: badges.map((badge) {
            final unlocked = badge.$2;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: unlocked
                    ? Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.6)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
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
                    size: 20,
                    color: unlocked
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        badge.$1,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  unlocked ? FontWeight.bold : FontWeight.w500,
                              color: unlocked
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                      ),
                      Text(
                        badge.$4,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: unlocked
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.7)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.6),
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

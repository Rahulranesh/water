import 'package:flutter/material.dart';

import '../../core/services/drink_advice_service.dart';

/// Shows full drink advice in a bottom sheet.
void showDrinkAdviceSheet(BuildContext context, DrinkAdvice advice) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _DrinkAdviceSheet(advice: advice),
  );
}

class _DrinkAdviceSheet extends StatelessWidget {
  const _DrinkAdviceSheet({required this.advice});

  final DrinkAdvice advice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final levelColor = _levelColor(advice.level, scheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: advice.drink.color.withValues(alpha: 0.14),
                ),
                child: Center(
                  child: Text(
                    advice.drink.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advice.drink.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(advice.levelEmoji),
                        const SizedBox(width: 6),
                        Text(
                          advice.levelLabel,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: levelColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Headline pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: levelColor.withValues(alpha: 0.1),
              border: Border.all(color: levelColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              advice.title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            advice.reason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              _StatChip(
                icon: Icons.local_drink_rounded,
                label: advice.recommendedMl > 0
                    ? '${advice.recommendedMl} ml today'
                    : 'Avoid today',
                color: levelColor,
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.repeat_rounded,
                label: advice.splits == 0
                    ? 'Skip today'
                    : '${advice.splits} serving${advice.splits == 1 ? '' : 's'}/day',
                color: scheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _levelColor(AdviceLevel level, ColorScheme scheme) {
    return switch (level) {
      AdviceLevel.great => const Color(0xFF22c55e),
      AdviceLevel.good => const Color(0xFFca8a04),
      AdviceLevel.caution => const Color(0xFFea580c),
      AdviceLevel.avoid => scheme.error,
    };
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

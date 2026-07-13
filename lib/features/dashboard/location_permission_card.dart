import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/hydro_controller.dart';

/// Full-width, animated permission request card shown when location
/// access has not yet been granted or dismissed.
class LocationPermissionCard extends ConsumerWidget {
  const LocationPermissionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.12),
            scheme.secondary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: scheme.primary,
                    size: 26,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.92, 0.92),
                      end: const Offset(1.05, 1.05),
                      duration: 1800.ms,
                    ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weather-Aware Hydration',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Adjust your goal to the real temperature.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'HydroFlow reads the local temperature at your location to '
              'precisely adjust your daily water goal, set the right number '
              'of reminder splits, and give you drink-by-drink advice for '
              'the heat you\'re actually in.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => ref
                        .read(hydroControllerProvider.notifier)
                        .fetchWeatherAndLocation(),
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Allow Location'),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => ref
                      .read(hydroControllerProvider.notifier)
                      .dismissLocationPrompt(),
                  child: const Text('Not Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

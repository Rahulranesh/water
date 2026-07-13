import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/hydro_state.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/fcm_service.dart';
import '../../core/services/hydro_controller.dart';
import '../../core/services/reminder_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydroControllerProvider);
    final controller = ref.read(hydroControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _SettingsGroup(
            title: 'Goal & Profile',
            children: [
              _MascotTile(state: state),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: const Text('Daily Hydration Goal', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Your daily target is ${state.settings.profile?.dailyGoalMl ?? 2500} ml. Modify parameters to recalculate.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: TextButton(
                  onPressed: controller.resetProfile,
                  child: const Text('Recalculate'),
                ),
              ),
            ],
          ),
          _SettingsGroup(
            title: 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Unit System', style: TextStyle(fontWeight: FontWeight.w600)),
                    SegmentedButton<UnitSystem>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: UnitSystem.ml, label: Text('ml')),
                        ButtonSegment(value: UnitSystem.oz, label: Text('oz')),
                      ],
                      selected: {state.settings.unitSystem},
                      onSelectionChanged: (value) => controller.updateUnit(value.first),
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
              ),
              _ThemeSelector(state: state),
            ],
          ),
          _SettingsGroup(
            title: 'Reminders',
            children: [
              _ReminderSettingsSection(state: state),
            ],
          ),
          _SettingsGroup(
            title: 'Custom Beverages',
            children: [
              _CustomDrinksSection(state: state),
            ],
          ),
          _SettingsGroup(
            title: 'Monetization & Ads',
            children: [
              _MonetizationSection(state: state),
            ],
          ),
          _SettingsGroup(
            title: 'Data & System',
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                title: const Text('Backup Data', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Generate and preview local storage data in CSV format.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showCsv(context, state),
              ),
              const _FcmTokenTile(),
            ],
          ),
        ],
      ),
    );
  }

  void _showCsv(BuildContext context, HydroState state) {
    final csv = const ExportService().entriesToCsv(state.entries);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('CSV Export Preview', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(child: SelectableText(csv)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final list = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      list.add(children[i]);
      if (i < children.length - 1) {
        list.add(Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.6),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8, top: 22),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: .3),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: list,
          ),
        ),
      ],
    );
  }
}

class _MascotTile extends ConsumerWidget {
  const _MascotTile({required this.state});

  final HydroState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController(text: state.settings.mascotName);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Text(
              mascotEmoji(state.mascotMood),
              style: const TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Mascot Name',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: ref.read(hydroControllerProvider.notifier).updateMascotName,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector({required this.state});

  final HydroState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(hydroControllerProvider.notifier);
    final colors = const [
      Color(0xFF00A8A8),
      Color(0xFF1FB6FF),
      Color(0xFFE25A7B),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('Auto')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {state.settings.themeMode},
                onSelectionChanged: (value) => controller.updateThemeMode(value.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Accent Color', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Row(
                children: colors.map((color) {
                  final isSelected = state.settings.accent.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => controller.updateAccent(color),
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderSettingsSection extends ConsumerWidget {
  const _ReminderSettingsSection({required this.state});

  final HydroState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = state.settings.profile;
    final reminders = state.settings.reminders;
    final schedule = profile == null
        ? <TimeOfDay>[]
        : const ReminderService().buildSchedule(profile, reminders);
    final controller = ref.read(hydroControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: const Text('Smart Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            const ReminderService().nativeNotificationsAvailable
                ? 'Natively scheduling reminders on this device.'
                : 'Reminders simulate triggers (Weekend enabled).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          value: reminders.enabled,
          onChanged: (value) => controller.updateReminderSettings(
            reminders.copyWith(enabled: value),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('Adaptive Nudges', style: TextStyle(fontWeight: FontWeight.w600)),
          value: reminders.adaptive,
          onChanged: (value) => controller.updateReminderSettings(
            reminders.copyWith(adaptive: value),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: const Text('Weekend Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
          value: reminders.weekendsEnabled,
          onChanged: (value) => controller.updateReminderSettings(
            reminders.copyWith(weekendsEnabled: value),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Interval Frequency', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${reminders.intervalMinutes} min',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                min: 45,
                max: 180,
                divisions: 9,
                value: reminders.intervalMinutes.toDouble(),
                onChanged: (value) => controller.updateReminderSettings(
                  reminders.copyWith(intervalMinutes: value.round()),
                ),
              ),
            ],
          ),
        ),
        if (schedule.isNotEmpty) ...[
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCHEDULED TIMES',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: schedule.take(8).map((time) {
                    return Chip(
                      label: Text(time.format(context)),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await const ReminderService().showInstantTestNotification();
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Test Notification'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: profile == null
                      ? null
                      : () async {
                          await const ReminderService().requestPermissionsAndSchedule(
                            profile: profile,
                            settings: reminders,
                            weather: state.settings.weather,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reminder schedule synchronized.'),
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Sync Schedule'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomDrinksSection extends ConsumerWidget {
  const _CustomDrinksSection({required this.state});

  final HydroState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitReached = !state.settings.isPro && state.customDrinks.length >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: const Text('Hydration Multiplex', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            limitReached
                ? 'Limit of 2 custom drinks reached on Free version.'
                : 'Create beverages with custom hydration multiplier coefficients.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: TextButton.icon(
            onPressed: limitReached ? null : () => _showCustomDrinkSheet(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add'),
          ),
        ),
        if (state.customDrinks.isNotEmpty) ...[
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          ),
          ...state.customDrinks.map((drink) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Text(drink.emoji, style: const TextStyle(fontSize: 24)),
              title: Text(drink.label, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('${drink.multiplier}x multiplier hydration coefficient'),
              trailing: IconButton(
                onPressed: () => ref.read(hydroControllerProvider.notifier).removeCustomDrink(drink.id),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            );
          }),
        ],
      ],
    );
  }

  Future<void> _showCustomDrinkSheet(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController(text: 'Coconut Water');
    final emoji = TextEditingController(text: '🥥');
    var multiplier = 0.95;
    final drink = await showModalBottomSheet<DrinkOption>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    'New Beverage Creator',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emoji,
                    decoration: const InputDecoration(labelText: 'Emoji Icon'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hydration Coefficient', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${multiplier.toStringAsFixed(2)}x',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    min: .3,
                    max: 1.2,
                    divisions: 18,
                    value: multiplier,
                    onChanged: (value) => setState(() => multiplier = value),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        DrinkOption(
                          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
                          label: name.text.trim().isEmpty ? 'Custom Drink' : name.text.trim(),
                          multiplier: multiplier,
                          color: const Color(0xFF00A8A8),
                          emoji: emoji.text.trim().isEmpty ? '💧' : emoji.text.trim(),
                          isCustom: true,
                        ),
                      );
                    },
                    child: const Text('Create Beverage'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (drink != null) {
      await ref.read(hydroControllerProvider.notifier).addCustomDrink(drink);
    }
  }
}

class _MonetizationSection extends ConsumerWidget {
  const _MonetizationSection({required this.state});

  final HydroState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = state.settings.isPro;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPro)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(
              Icons.stars_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 26,
            ),
            title: const Text('HydroFlow PRO Active', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Lifetime premium features unlocked. Thank you for your support!'),
            trailing: Icon(
              Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        else ...[
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(
              Icons.stars_rounded,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              size: 26,
            ),
            title: const Text('Upgrade to HydroFlow PRO', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Remove ads, unlock unlimited beverages, and support the app.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showUpgradeDialog(context, ref),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () async {
                final earned = await const AdService().showRewardedAdForAdFreeHour();
                if (earned) await ref.read(hydroControllerProvider.notifier).grantRewardedAdFreeHour();
              },
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text('Watch Ad (1 Hr Ad-Free)'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: scheme.outlineVariant,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    '👑',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'HydroFlow PRO',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Unlock the ultimate hydration companion and support development!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              const _UpgradeFeatureRow(
                icon: Icons.block_rounded,
                title: 'Ad-Free Experience',
                description: 'Remove all banners and popups instantly.',
              ),
              const SizedBox(height: 16),
              const _UpgradeFeatureRow(
                icon: Icons.local_cafe_rounded,
                title: 'Unlimited Custom Beverages',
                description: 'Add as many custom drinks as you like (limited to 2 in free).',
              ),
              const SizedBox(height: 16),
              const _UpgradeFeatureRow(
                icon: Icons.thermostat_rounded,
                title: 'Weather-Aware Alerts',
                description: 'Adaptive splits based on real-time temperature updates.',
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () async {
                  await ref.read(hydroControllerProvider.notifier).toggleProPreview();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Welcome to HydroFlow PRO! 🎉')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Upgrade for \$2.99 / Life', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpgradeFeatureRow extends StatelessWidget {
  const _UpgradeFeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.primary.withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: scheme.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FcmTokenTile extends StatefulWidget {
  const _FcmTokenTile();

  @override
  State<_FcmTokenTile> createState() => _FcmTokenTileState();
}

class _FcmTokenTileState extends State<_FcmTokenTile> {
  String _token = 'Fetching token...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchToken();
  }

  Future<void> _fetchToken() async {
    final token = await FcmService().getDeviceToken();
    if (mounted) {
      setState(() {
        _token = token ?? 'Failed to fetch FCM Token or not supported on this platform';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: const Text('FCM Device Token', style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        _token,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy_all_rounded),
        tooltip: 'Copy FCM Token',
        onPressed: _isLoading || _token.startsWith('Failed') || _token.startsWith('Fetching')
            ? null
            : () async {
                await Clipboard.setData(ClipboardData(text: _token));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('FCM Token copied to clipboard')),
                );
              },
      ),
    );
  }
}


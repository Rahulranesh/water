import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    return CupertinoPageScaffold(
      child: Material(
        color: Colors.transparent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: const Text('Settings'),
              border: null,
              backgroundColor: CupertinoTheme.of(context)
                  .barBackgroundColor
                  .withValues(alpha: 0.82),
            ),
            SliverSafeArea(
              top: false,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  CupertinoListSection.insetGrouped(
                    header: const Text('PROFILE & MASCOT'),
                    children: [
                      _MascotTile(state: state),
                      CupertinoListTile.notched(
                        leading: const Icon(CupertinoIcons.person_crop_circle, color: CupertinoColors.systemBlue),
                        title: const Text('Daily Goal target'),
                        subtitle: Text(
                          'Target is ${state.settings.profile?.dailyGoalMl ?? 2500} ml. Tap to recalculate.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: controller.resetProfile,
                          child: const Text('Recalculate'),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),
                  
                  CupertinoListSection.insetGrouped(
                    header: const Text('APPEARANCE'),
                    children: [
                      CupertinoListTile.notched(
                        leading: const Icon(CupertinoIcons.slider_horizontal_3, color: CupertinoColors.systemGreen),
                        title: const Text('Unit System'),
                        trailing: CupertinoSlidingSegmentedControl<UnitSystem>(
                          groupValue: state.settings.unitSystem,
                          children: const {
                            UnitSystem.ml: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              child: Text('ml', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                            UnitSystem.oz: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              child: Text('oz', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          },
                          onValueChanged: (value) {
                            if (value != null) controller.updateUnit(value);
                          },
                        ),
                      ),
                      _ThemeSelectorTile(state: state),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 60.ms, duration: 350.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),

                  CupertinoListSection.insetGrouped(
                    header: const Text('ALERTS & REMINDERS'),
                    children: [
                      _ReminderSettingsSection(state: state),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 350.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),

                  CupertinoListSection.insetGrouped(
                    header: const Text('BEVERAGE MANAGEMENT'),
                    children: [
                      _CustomDrinksSection(state: state),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 180.ms, duration: 350.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),

                  CupertinoListSection.insetGrouped(
                    header: const Text('MONETIZATION'),
                    children: [
                      _MonetizationSection(state: state),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 240.ms, duration: 350.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),

                  CupertinoListSection.insetGrouped(
                    header: const Text('DATA & LOGS'),
                    children: [
                      CupertinoListTile.notched(
                        leading: const Icon(CupertinoIcons.arrow_down_doc, color: CupertinoColors.systemPink),
                        title: const Text('Backup CSV logs'),
                        subtitle: const Text('Generate and copy CSV logs of your history.'),
                        trailing: const Icon(CupertinoIcons.chevron_right, color: Color(0xFF8E8E93), size: 16),
                        onTap: () => _showCsv(context, state),
                      ),
                      const _FcmTokenTile(),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 350.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuad),

                  const SizedBox(height: 36),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCsv(BuildContext context, HydroState state) {
    final csv = const ExportService().entriesToCsv(state.entries);
    showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('CSV Export'),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
                child: SelectableText(
                  csv,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.pop(context);
              },
              child: const Text('Copy to Clipboard'),
            ),
          ],
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: CupertinoTextField(
                controller: textController,
                placeholder: 'Mascot Name',
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemGroupedBackground,
                    context,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                onSubmitted: ref.read(hydroControllerProvider.notifier).updateMascotName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelectorTile extends ConsumerWidget {
  const _ThemeSelectorTile({required this.state});

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.color_filter, color: CupertinoColors.systemIndigo),
                  const SizedBox(width: 12),
                  const Text('Theme Mode', style: TextStyle(fontSize: 16)),
                ],
              ),
              CupertinoSlidingSegmentedControl<ThemeMode>(
                groupValue: state.settings.themeMode,
                children: const {
                  ThemeMode.system: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Auto', style: TextStyle(fontSize: 12)),
                  ),
                  ThemeMode.light: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Light', style: TextStyle(fontSize: 12)),
                  ),
                  ThemeMode.dark: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Dark', style: TextStyle(fontSize: 12)),
                  ),
                },
                onValueChanged: (value) {
                  if (value != null) controller.updateThemeMode(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.paintbrush, color: CupertinoColors.systemPurple),
                  const SizedBox(width: 12),
                  const Text('Accent Tint', style: TextStyle(fontSize: 16)),
                ],
              ),
              const Spacer(),
              Row(
                children: colors.map((color) {
                  final isSelected = state.settings.accent.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => controller.updateAccent(color),
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? CupertinoDynamicColor.resolve(CupertinoColors.label, context)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              CupertinoIcons.checkmark,
                              size: 11,
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
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoListTile.notched(
          leading: const Icon(CupertinoIcons.bell_fill, color: CupertinoColors.systemRed),
          title: const Text('Smart Reminders'),
          subtitle: Text(
            const ReminderService().nativeNotificationsAvailable
                ? 'Natively scheduling reminders on device.'
                : 'Reminders simulate triggers (Weekend active).',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: CupertinoSwitch(
            value: reminders.enabled,
            onChanged: (value) => controller.updateReminderSettings(
              reminders.copyWith(enabled: value),
            ),
          ),
        ),
        CupertinoListTile.notched(
          leading: const Icon(CupertinoIcons.sparkles, color: CupertinoColors.systemOrange),
          title: const Text('Adaptive Nudges'),
          subtitle: const Text('Adjust times automatically to weather bounds.', style: TextStyle(fontSize: 11)),
          trailing: CupertinoSwitch(
            value: reminders.adaptive,
            onChanged: (value) => controller.updateReminderSettings(
              reminders.copyWith(adaptive: value),
            ),
          ),
        ),
        CupertinoListTile.notched(
          leading: const Icon(CupertinoIcons.calendar, color: CupertinoColors.systemYellow),
          title: const Text('Weekend Reminders'),
          trailing: CupertinoSwitch(
            value: reminders.weekendsEnabled,
            onChanged: (value) => controller.updateReminderSettings(
              reminders.copyWith(weekendsEnabled: value),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.alarm, color: CupertinoColors.systemTeal),
                      const SizedBox(width: 12),
                      const Text('Interval Frequency', style: TextStyle(fontSize: 15)),
                    ],
                  ),
                  Text(
                    '${reminders.intervalMinutes} min',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Material(
                color: Colors.transparent,
                child: Slider(
                  min: 45,
                  max: 180,
                  divisions: 9,
                  value: reminders.intervalMinutes.toDouble(),
                  onChanged: (value) => controller.updateReminderSettings(
                    reminders.copyWith(intervalMinutes: value.round()),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (schedule.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SCHEDULED TIMES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: schedule.take(8).map((time) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        time.format(context),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                  borderRadius: BorderRadius.circular(10),
                  onPressed: () async {
                    await const ReminderService().showInstantTestNotification();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.paperplane, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Send Test',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: profile == null
                      ? null
                      : () async {
                          await const ReminderService().requestPermissionsAndSchedule(
                            profile: profile,
                            settings: reminders,
                            weather: state.settings.weather,
                          );
                          if (context.mounted) {
                            showCupertinoDialog<void>(
                              context: context,
                              builder: (context) => CupertinoAlertDialog(
                                title: const Text('Schedule Synced'),
                                content: const Text('Your hydration alarms have been refreshed.'),
                                actions: [
                                  CupertinoDialogAction(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  )
                                ],
                              ),
                            );
                          }
                        },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.refresh, size: 16),
                      SizedBox(width: 8),
                      Text('Sync Alarm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
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

class _CustomDrinksSection extends ConsumerWidget {
  const _CustomDrinksSection({required this.state});

  final HydroState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitReached = !state.settings.isPro && state.customDrinks.length >= 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoListTile.notched(
          leading: const Icon(CupertinoIcons.drop, color: CupertinoColors.systemTeal),
          title: const Text('Hydration Multiplex'),
          subtitle: Text(
            limitReached
                ? 'Free version limit of 2 reached.'
                : 'Create drinks with multiplier parameters.',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: limitReached ? null : () => _showCustomDrinkSheet(context, ref),
            child: const Text('Create'),
          ),
        ),
        if (state.customDrinks.isNotEmpty) ...[
          ...state.customDrinks.map((drink) {
            return CupertinoListTile.notched(
              leading: Text(drink.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(drink.label, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('${drink.multiplier}x multiplier hydration coefficient', style: const TextStyle(fontSize: 11)),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => ref.read(hydroControllerProvider.notifier).removeCustomDrink(drink.id),
                child: const Icon(CupertinoIcons.trash, color: CupertinoColors.destructiveRed, size: 18),
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

    final notifier = ref.read(hydroControllerProvider.notifier);
    final drink = await showCupertinoModalPopup<DrinkOption>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoActionSheet(
              title: const Text('New Beverage Creator'),
              message: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    CupertinoTextField(
                      controller: name,
                      placeholder: 'Name',
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: CupertinoDynamicColor.resolve(
                          CupertinoColors.systemGroupedBackground,
                          context,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CupertinoTextField(
                      controller: emoji,
                      placeholder: 'Emoji Icon',
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: CupertinoDynamicColor.resolve(
                          CupertinoColors.systemGroupedBackground,
                          context,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hydration Coefficient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                  ],
                ),
              ),
              actions: [
                CupertinoActionSheetAction(
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
              cancelButton: CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context),
                isDestructiveAction: true,
                child: const Text('Cancel'),
              ),
            );
          },
        );
      },
    );

    if (drink != null) {
      await notifier.addCustomDrink(drink);
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
          CupertinoListTile.notched(
            leading: Icon(
              CupertinoIcons.star_fill,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            title: const Text('HydroFlow PRO Active', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Lifetime premium features unlocked.', style: TextStyle(fontSize: 11)),
            trailing: Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        else ...[
          CupertinoListTile.notched(
            leading: const Icon(
              CupertinoIcons.star,
              color: CupertinoColors.systemOrange,
              size: 20,
            ),
            title: const Text('Upgrade to HydroFlow PRO', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Unlock weather bounds and remove all ads.', style: TextStyle(fontSize: 11)),
            trailing: const Icon(CupertinoIcons.chevron_right, color: Color(0xFF8E8E93), size: 16),
            onTap: () => _showUpgradeDialog(context, ref),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              onPressed: () async {
                final earned = await const AdService().showRewardedAdForAdFreeHour();
                if (earned) await ref.read(hydroControllerProvider.notifier).grantRewardedAdFreeHour();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.play_circle, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Watch Ad (1 Hr Ad-Free)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2.5),
                      color: const Color(0xFFC7C7CC),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Text('👑', style: TextStyle(fontSize: 32)),
                    SizedBox(width: 12),
                    Text(
                      'HydroFlow PRO',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unlock the ultimate hydration companion and support development!',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                const _UpgradeFeatureRow(
                  icon: CupertinoIcons.slash_circle_fill,
                  title: 'Ad-Free Experience',
                  description: 'Remove all banners and popups instantly.',
                ),
                const SizedBox(height: 16),
                const _UpgradeFeatureRow(
                  icon: CupertinoIcons.drop_fill,
                  title: 'Unlimited Custom Beverages',
                  description: 'Add as many custom drinks as you like (limited to 2 in free).',
                ),
                const SizedBox(height: 16),
                const _UpgradeFeatureRow(
                  icon: CupertinoIcons.thermometer,
                  title: 'Weather-Aware Alerts',
                  description: 'Adaptive splits based on real-time temperature updates.',
                ),
                const SizedBox(height: 32),
                CupertinoButton.filled(
                  borderRadius: BorderRadius.circular(14),
                  onPressed: () async {
                    await ref.read(hydroControllerProvider.notifier).toggleProPreview();
                    if (context.mounted) {
                      Navigator.pop(context);
                      showCupertinoDialog<void>(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Welcome to PRO 🎉'),
                          content: const Text('Thank you for unlocking HydroFlow PRO!'),
                          actions: [
                            CupertinoDialogAction(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Let\'s Go'),
                            )
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('Upgrade for \$2.99 / Life', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x1A007AFF),
          ),
          child: Icon(icon, color: CupertinoColors.systemBlue, size: 20),
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
                style: const TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 12),
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
    return CupertinoListTile.notched(
      leading: const Icon(CupertinoIcons.device_phone_portrait, color: Color(0xFF8E8E93)),
      title: const Text('FCM Device Token'),
      subtitle: Text(
        _token,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11),
      ),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _isLoading || _token.startsWith('Failed') || _token.startsWith('Fetching')
            ? null
            : () async {
                await Clipboard.setData(ClipboardData(text: _token));
                if (!context.mounted) return;
                showCupertinoDialog<void>(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    title: const Text('Token Copied'),
                    content: const Text('FCM Token copied to clipboard.'),
                    actions: [
                      CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      )
                    ],
                  ),
                );
              },
        child: const Icon(CupertinoIcons.doc_on_doc, size: 20),
      ),
    );
  }
}

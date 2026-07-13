import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/hydro_state.dart';
import '../../core/services/hydration_calculator.dart';
import '../../core/services/hydro_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController(text: '170');
  final _ageController = TextEditingController(text: '28');

  String _gender = 'Prefer not to say';
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  Climate _climate = Climate.temperate;
  GoalType _goalType = GoalType.general;
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 30);

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final predictedGoal = const HydrationCalculator().dailyGoalMl(
      weightKg: double.tryParse(_weightController.text) ?? 70,
      activityLevel: _activityLevel,
      climate: _climate,
      goalType: _goalType,
    );

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            children: [
              const SizedBox(height: 12),
              _LogoMark(goal: predictedGoal),
              const SizedBox(height: 32),
              
              // Gender Select
              _SlidingSegmentedField<String>(
                label: 'Gender',
                value: _gender,
                values: const ['Female', 'Male', 'Prefer not to say'],
                labelFor: (v) => v,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 24),

              // Weight & Height
              Row(
                children: [
                  Expanded(
                    child: _CupertinoNumberField(
                      controller: _weightController,
                      label: 'Weight',
                      suffix: 'kg',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _CupertinoNumberField(
                      controller: _heightController,
                      label: 'Height',
                      suffix: 'cm',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Age
              _CupertinoNumberField(
                controller: _ageController,
                label: 'Age',
                suffix: 'years',
              ),
              const SizedBox(height: 24),

              // Activity Level Select
              _SlidingSegmentedField<ActivityLevel>(
                label: 'Activity Level',
                value: _activityLevel,
                values: ActivityLevel.values,
                labelFor: _activityLabel,
                onChanged: (v) => setState(() => _activityLevel = v),
              ),
              const SizedBox(height: 24),

              // Climate Select
              _SlidingSegmentedField<Climate>(
                label: 'Climate',
                value: _climate,
                values: Climate.values,
                labelFor: _climateLabel,
                onChanged: (v) => setState(() => _climate = v),
              ),
              const SizedBox(height: 24),

              // Goal Focus Select
              _SlidingSegmentedField<GoalType>(
                label: 'Goal Focus',
                value: _goalType,
                values: GoalType.values,
                labelFor: _goalLabel,
                onChanged: (v) => setState(() => _goalType = v),
              ),
              const SizedBox(height: 28),

              // Wake / Sleep times
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Wake',
                      value: _wakeTime,
                      onTap: () =>
                          _pickTime(_wakeTime, (time) => _wakeTime = time),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TimeButton(
                      label: 'Sleep',
                      value: _sleepTime,
                      onTap: () =>
                          _pickTime(_sleepTime, (time) => _sleepTime = time),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              if (_goalType == GoalType.pregnancySafe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Pregnancy-safe mode adds a gentle buffer. Please consult a healthcare professional for specific needs.',
                    style: TextStyle(
                      color: CupertinoDynamicColor.resolve(
                        CupertinoColors.secondaryLabel,
                        context,
                      ),
                      fontSize: 12,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 12),
              CupertinoButton.filled(
                borderRadius: BorderRadius.circular(14),
                onPressed: () => _finish(predictedGoal),
                child: Text('Start with $predictedGoal ml / day', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(
    TimeOfDay initial,
    ValueChanged<TimeOfDay> update,
  ) async {
    final initialDateTime = DateTime(2026, 1, 1, initial.hour, initial.minute);
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
        return Container(
          height: 280,
          color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemBackground,
          child: Column(
            children: [
              Container(
                color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel', style: TextStyle(color: CupertinoColors.destructiveRed)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    CupertinoButton(
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  onDateTimeChanged: (dateTime) {
                    update(TimeOfDay(hour: dateTime.hour, minute: dateTime.minute));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _finish(int dailyGoalMl) async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final profile = UserProfile(
      gender: _gender,
      weightKg: double.parse(_weightController.text),
      heightCm: double.parse(_heightController.text),
      age: int.parse(_ageController.text),
      activityLevel: _activityLevel,
      climate: _climate,
      wakeTime: _wakeTime,
      sleepTime: _sleepTime,
      goalType: _goalType,
      dailyGoalMl: dailyGoalMl,
    );
    await ref
        .read(hydroControllerProvider.notifier)
        .completeOnboarding(profile);
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.goal});

  final int goal;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [secondary, primary],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              CupertinoIcons.drop_fill,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Personalize HydroFlow',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A personalized loop hydration, tuned to $goal ml.',
          style: TextStyle(
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.secondaryLabel,
              context,
            ),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CupertinoNumberField extends StatelessWidget {
  const _CupertinoNumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            decoration: InputDecoration(
              suffixText: suffix,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              final number = double.tryParse(value ?? '');
              if (number == null || number <= 0) return 'Enter valid value';
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _SlidingSegmentedField<T extends Object> extends StatelessWidget {
  const _SlidingSegmentedField({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<T>(
            groupValue: value,
            children: {
              for (final val in values)
                val: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    labelFor(val),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            },
            onValueChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      onPressed: onTap,
      child: Container(
        alignment: Alignment.center,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoDynamicColor.resolve(CupertinoColors.separator, context),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.clock_fill,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '$label: ${value.format(context)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: CupertinoDynamicColor.resolve(CupertinoColors.label, context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _activityLabel(ActivityLevel level) {
  return switch (level) {
    ActivityLevel.low => 'Low',
    ActivityLevel.moderate => 'Moderate',
    ActivityLevel.high => 'High',
  };
}

String _climateLabel(Climate climate) {
  return switch (climate) {
    Climate.cold => 'Cold',
    Climate.temperate => 'Temperate',
    Climate.hotHumid => 'Hot',
  };
}

String _goalLabel(GoalType type) {
  return switch (type) {
    GoalType.general => 'General',
    GoalType.weightLoss => 'Weight loss',
    GoalType.fitness => 'Fitness',
    GoalType.pregnancySafe => 'Pregnancy',
  };
}

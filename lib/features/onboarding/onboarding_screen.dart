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

    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          children: [
            const SizedBox(height: 12),
            _LogoMark(goal: predictedGoal),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SegmentedField<String>(
                    label: 'Gender',
                    value: _gender,
                    values: const ['Female', 'Male', 'Prefer not to say'],
                    labelFor: (value) => value,
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          controller: _weightController,
                          label: 'Weight',
                          suffix: 'kg',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _NumberField(
                          controller: _heightController,
                          label: 'Height',
                          suffix: 'cm',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _NumberField(
                    controller: _ageController,
                    label: 'Age',
                    suffix: 'years',
                  ),
                  const SizedBox(height: 20),
                  _SegmentedField<ActivityLevel>(
                    label: 'Activity Level',
                    value: _activityLevel,
                    values: ActivityLevel.values,
                    labelFor: _activityLabel,
                    onChanged: (value) =>
                        setState(() => _activityLevel = value),
                  ),
                  const SizedBox(height: 20),
                  _SegmentedField<Climate>(
                    label: 'Climate',
                    value: _climate,
                    values: Climate.values,
                    labelFor: _climateLabel,
                    onChanged: (value) => setState(() => _climate = value),
                  ),
                  const SizedBox(height: 20),
                  _SegmentedField<GoalType>(
                    label: 'Goal Focus',
                    value: _goalType,
                    values: GoalType.values,
                    labelFor: _goalLabel,
                    onChanged: (value) => setState(() => _goalType = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            if (_goalType == GoalType.pregnancySafe)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Pregnancy-safe mode adds a gentle buffer. Please consult a healthcare professional for specific needs.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _finish(predictedGoal),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text('Start with $predictedGoal ml / day'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(
    TimeOfDay initial,
    ValueChanged<TimeOfDay> update,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() => update(picked));
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
              colors: [
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.primary,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.water_drop_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Personalize HydroFlow',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'A personalized loop hydration, tuned to $goal ml.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
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
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        final number = double.tryParse(value ?? '');
        if (number == null || number <= 0) return 'Enter valid value';
        return null;
      },
    );
  }
}

class _SegmentedField<T extends Object> extends StatelessWidget {
  const _SegmentedField({
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map<Widget>((item) {
              final isSelected = item == value;
              return ChoiceChip(
                selected: isSelected,
                label: Text(labelFor(item)),
                onSelected: (_) => onChanged(item),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            }).toList(),
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
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded,
              size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ${value.format(context)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
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
    GoalType.pregnancySafe => 'Pregnancy-safe',
  };
}

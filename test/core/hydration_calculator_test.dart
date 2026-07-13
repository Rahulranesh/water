import 'package:flutter_test/flutter_test.dart';
import 'package:hydroflow/core/models/hydro_state.dart';
import 'package:hydroflow/core/services/hydration_calculator.dart';

void main() {
  const calculator = HydrationCalculator();

  test('uses the requested wellness heuristic and modifiers', () {
    final result = calculator.dailyGoalMl(
      weightKg: 70,
      activityLevel: ActivityLevel.moderate,
      climate: Climate.hotHumid,
      goalType: GoalType.weightLoss,
    );

    expect(result, 3360);
  });

  test('clamps low and high goals into sane bounds', () {
    expect(
      calculator.dailyGoalMl(
        weightKg: 35,
        activityLevel: ActivityLevel.low,
        climate: Climate.cold,
        goalType: GoalType.general,
      ),
      1500,
    );

    expect(
      calculator.dailyGoalMl(
        weightKg: 150,
        activityLevel: ActivityLevel.high,
        climate: Climate.hotHumid,
        goalType: GoalType.pregnancySafe,
      ),
      4000,
    );
  });
}

import '../models/hydro_state.dart';

class HydrationCalculator {
  const HydrationCalculator();

  int dailyGoalMl({
    required double weightKg,
    required ActivityLevel activityLevel,
    required Climate climate,
    required GoalType goalType,
  }) {
    var baseMl = weightKg * 33;

    switch (activityLevel) {
      case ActivityLevel.low:
        break;
      case ActivityLevel.moderate:
        baseMl += 350;
      case ActivityLevel.high:
        baseMl += 700;
    }

    switch (climate) {
      case Climate.hotHumid:
        baseMl += 400;
      case Climate.temperate:
        break;
      case Climate.cold:
        baseMl -= 100;
    }

    switch (goalType) {
      case GoalType.weightLoss:
      case GoalType.pregnancySafe:
        baseMl += 300;
      case GoalType.general:
      case GoalType.fitness:
        break;
    }

    return baseMl.clamp(1500, 4000).round();
  }
}

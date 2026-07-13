import '../models/hydro_state.dart';

/// Advice levels for a drink at a given temperature.
enum AdviceLevel { great, good, caution, avoid }

/// Temperature-specific advice for a single drink.
class DrinkAdvice {
  const DrinkAdvice({
    required this.drink,
    required this.level,
    required this.recommendedMl,
    required this.title,
    required this.reason,
    required this.splits,
  });

  final DrinkOption drink;
  final AdviceLevel level;

  /// Recommended intake in ml for today at this temperature.
  final int recommendedMl;

  /// Short headline, e.g. "Limit to 1 cup".
  final String title;

  /// Full reasoning paragraph.
  final String reason;

  /// How many times per day this drink is suitable.
  final int splits;

  String get levelEmoji => switch (level) {
        AdviceLevel.great => '🟢',
        AdviceLevel.good => '🟡',
        AdviceLevel.caution => '🟠',
        AdviceLevel.avoid => '🔴',
      };

  String get levelLabel => switch (level) {
        AdviceLevel.great => 'Great choice',
        AdviceLevel.good => 'Fine in moderation',
        AdviceLevel.caution => 'Use caution',
        AdviceLevel.avoid => 'Not recommended',
      };

  String get levelColor => switch (level) {
        AdviceLevel.great => '#22c55e',
        AdviceLevel.good => '#eab308',
        AdviceLevel.caution => '#f97316',
        AdviceLevel.avoid => '#ef4444',
      };
}

/// Pure-function service that returns [DrinkAdvice] for a drink at a temperature.
class DrinkAdviceService {
  const DrinkAdviceService();

  DrinkAdvice adviceFor(DrinkOption drink, double temperatureC) {
    final t = temperatureC;
    return switch (drink.id) {
      'water' => _waterAdvice(drink, t),
      'coffee' => _coffeeAdvice(drink, t),
      'tea' => _teaAdvice(drink, t),
      'juice' => _juiceAdvice(drink, t),
      'soda' => _sodaAdvice(drink, t),
      'milk' => _milkAdvice(drink, t),
      'sports' => _sportsAdvice(drink, t),
      'alcohol' => _alcoholAdvice(drink, t),
      _ => _genericAdvice(drink, t),
    };
  }

  /// Returns advice for all standard drink kinds at the given temperature.
  List<DrinkAdvice> adviceForAll(
      List<DrinkOption> drinks, double temperatureC) {
    return drinks.map((d) => adviceFor(d, temperatureC)).toList();
  }

  // ── Individual drink rules ────────────────────────────────────────────────

  DrinkAdvice _waterAdvice(DrinkOption d, double t) {
    final int ml;
    final String title;
    final String reason;
    if (t >= 38) {
      ml = 3800;
      title = 'Drink frequently — extreme heat';
      reason =
          'At $t°C your body loses water rapidly through sweating. Aim for '
          '${ml}ml spread across all reminder intervals. Sip 200–300ml every '
          '45 minutes. Chilled water also helps lower core body temperature.';
    } else if (t >= 30) {
      ml = 3200;
      title = 'Stay on top of it';
      reason =
          'In hot weather above 30°C dehydration creeps up quickly. Keep a '
          'bottle close and take 250ml sips every 60 minutes, totalling '
          'roughly ${ml}ml today.';
    } else if (t >= 20) {
      ml = 2500;
      title = 'Your regular goal';
      reason =
          'Comfortable temperatures still require consistent hydration. '
          'Spread ${ml}ml evenly through your waking hours.';
    } else {
      ml = 2000;
      title = 'Cool weather — slightly less needed';
      reason =
          'You sweat less in cool air, so ${ml}ml covers your baseline needs. '
          'Don\'t skip water even when you\'re not thirsty — cold air can be '
          'dehydrating too.';
    }
    return DrinkAdvice(
      drink: d,
      level: AdviceLevel.great,
      recommendedMl: ml,
      title: title,
      reason: reason,
      splits: t >= 38 ? 16 : t >= 30 ? 12 : t >= 20 ? 9 : 7,
    );
  }

  DrinkAdvice _coffeeAdvice(DrinkOption d, double t) {
    if (t >= 32) {
      return DrinkAdvice(
        drink: d,
        level: AdviceLevel.caution,
        recommendedMl: 200,
        title: 'Max 1 cup — it\'s hot out',
        reason:
            'Caffeine is a mild diuretic — in ${t.round()}°C heat it can '
            'increase fluid loss and make dehydration worse. If you do have '
            'coffee, pair every cup with 300ml of water. Prefer iced coffee '
            'to avoid raising your core temp further.',
        splits: 1,
      );
    }
    if (t >= 20) {
      return DrinkAdvice(
        drink: d,
        level: AdviceLevel.good,
        recommendedMl: 400,
        title: '1–2 cups is fine',
        reason:
            'At moderate temperatures coffee\'s diuretic effect is minimal. '
            'Keep it to 1–2 cups and match each with a glass of water to '
            'maintain your hydration balance.',
        splits: 2,
      );
    }
    return DrinkAdvice(
      drink: d,
      level: AdviceLevel.great,
      recommendedMl: 600,
      title: 'Great for cold days',
      reason:
          'Coffee counts toward hydration in cool weather. 2–3 cups over the '
          'day adds to your fluid intake and provides warming comfort.',
      splits: 3,
    );
  }

  DrinkAdvice _teaAdvice(DrinkOption d, double t) {
    if (t >= 33) {
      return DrinkAdvice(
        drink: d,
        level: AdviceLevel.good,
        recommendedMl: 400,
        title: 'Opt for iced tea',
        reason:
            'Hot tea at ${t.round()}°C will raise your body temperature. '
            'Switch to chilled herbal or green iced tea — it hydrates and '
            'delivers antioxidants without the heat. Limit to 2 servings.',
        splits: 2,
      );
    }
    return DrinkAdvice(
      drink: d,
      level: AdviceLevel.great,
      recommendedMl: 600,
      title: 'Perfect beverage',
      reason:
          'Tea has a 0.9× hydration coefficient, almost as good as water. '
          'Herbal, green, or black tea all contribute meaningfully to your '
          'daily fluid goal. 2–3 cups is ideal.',
      splits: 3,
    );
  }

  DrinkAdvice _juiceAdvice(DrinkOption d, double t) {
    if (t >= 30) {
      return DrinkAdvice(
        drink: d,
        level: AdviceLevel.good,
        recommendedMl: 400,
        title: 'Good, but watch sugar',
        reason:
            'Fruit juice provides fluids and electrolytes helpful in heat, '
            'but high sugar content can slow gastric emptying. Dilute with '
            '50% water in extreme heat. Limit to 400ml today at ${t.round()}°C.',
        splits: 2,
      );
    }
    return DrinkAdvice(
      drink: d,
      level: AdviceLevel.great,
      recommendedMl: 600,
      title: 'Hydrating with vitamins',
      reason:
          'Juice contributes well to hydration and delivers vitamins. '
          '100% fruit juice counts as fluid — keep to 400–600ml to manage '
          'natural sugar intake.',
      splits: 2,
    );
  }

  DrinkAdvice _sodaAdvice(DrinkOption d, double t) {
    if (t >= 30) {
      return DrinkAdvice(
        drink: d,
        level: AdviceLevel.caution,
        recommendedMl: 250,
        title: 'Caution — poor hydrator in heat',
        reason:
            'Carbonated sugary drinks have a 0.75× hydration coefficient and '
            'the sugar can worsen dehydration in ${t.round()}°C heat. Have at '
            'most 1 can and drink 500ml of water alongside it.',
        splits: 1,
      );
    }
    return DrinkAdvice(
      drink: d,
      level: AdviceLevel.good,
      recommendedMl: 330,
      title: 'Fine occasionally',
      reason:
          'Soda contributes some fluid but its hydration ratio is only 0.75. '
          'Enjoy 1 serving but don\'t rely on it as your primary source.',
      splits: 1,
    );
  }

  DrinkAdvice _milkAdvice(DrinkOption d, double t) {
    if (t >= 35) {
      return DrinkAdvice(
        drink: d,
        level: AdviceLevel.caution,
        recommendedMl: 200,
        title: 'Lighter option in extreme heat',
        reason:
            'Milk is rich in protein and fats, which require energy to digest '
            'and can raise body heat. In ${t.round()}°C, stick to a small '
            'glass and prioritise water.',
        splits: 1,
      );
    }
    return DrinkAdvice(
      drink: d,
      level: AdviceLevel.great,
      recommendedMl: 500,
      title: 'Excellent recovery drink',
      reason:
          'Milk is one of the best recovery hydrators — electrolytes, protein '
          'and carbs aid fluid retention. A great post-workout or morning '
          'option at current temperatures.',
      splits: 2,
    );
  }

  DrinkAdvice _sportsAdvice(DrinkOption d, double t) {
    if (t >= 25) {
      return DrinkAdvice(
        drink: d,
        level: AdviceLevel.great,
        recommendedMl: 750,
        title: 'Ideal for today\'s heat',
        reason:
            'Sports drinks replenish sodium, potassium and carbohydrates lost '
            'through sweat — exactly what you need at ${t.round()}°C. '
            'Have 500–750ml spread across your activity window.',
        splits: 3,
      );
    }
    return DrinkAdvice(
      drink: d,
      level: AdviceLevel.good,
      recommendedMl: 500,
      title: 'Good if you\'re active',
      reason:
          'In cooler weather sports drinks are most useful during or after '
          'exercise. Without activity, water is sufficient and lower in sugar.',
      splits: 2,
    );
  }

  DrinkAdvice _alcoholAdvice(DrinkOption d, double t) {
    if (t >= 32) {
      return DrinkAdvice(
        drink: d,
        level: AdviceLevel.avoid,
        recommendedMl: 0,
        title: 'Avoid in this heat',
        reason:
            'Alcohol is a strong diuretic that greatly increases fluid loss. '
            'At ${t.round()}°C this can escalate to dangerous dehydration and '
            'heat exhaustion. If you choose to drink, have at least 500ml of '
            'water for every alcoholic drink.',
        splits: 0,
      );
    }
    return DrinkAdvice(
      drink: d,
      level: AdviceLevel.caution,
      recommendedMl: 150,
      title: 'Dehydrating — drink water alongside',
      reason:
          'Alcohol suppresses ADH (the hormone that conserves water), causing '
          'increased urination. For every alcoholic drink, match with '
          '250–300ml of water.',
      splits: 1,
    );
  }

  DrinkAdvice _genericAdvice(DrinkOption d, double t) {
    return DrinkAdvice(
      drink: d,
      level: AdviceLevel.good,
      recommendedMl: (500 * d.multiplier).round(),
      title: 'Custom beverage',
      reason:
          'This drink has a ${d.multiplier}× hydration coefficient. '
          'At ${t.round()}°C, keep your total fluid intake above your '
          'adjusted daily goal.',
      splits: 2,
    );
  }
}

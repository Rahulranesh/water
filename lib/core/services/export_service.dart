import 'package:csv/csv.dart';

import '../models/hydro_state.dart';

class ExportService {
  const ExportService();

  String entriesToCsv(List<IntakeEntry> entries) {
    final rows = [
      ['created_at', 'drink', 'amount_ml', 'multiplier', 'effective_ml'],
      ...entries.map(
        (entry) => [
          entry.createdAt.toIso8601String(),
          entry.drink.label,
          entry.amountMl,
          entry.drink.multiplier,
          entry.effectiveMl,
        ],
      ),
    ];
    return csv.encode(rows);
  }
}

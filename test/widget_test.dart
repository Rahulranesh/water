import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydroflow/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows onboarding on first launch', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ProviderScope(child: HydroFlowApp()));
    await tester.pump();

    expect(find.text('Personalize HydroFlow'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
  });
}

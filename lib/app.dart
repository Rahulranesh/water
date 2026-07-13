import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/hydro_controller.dart';
import 'core/theme/hydro_theme.dart';
import 'features/dashboard/hydro_shell.dart';
import 'features/onboarding/onboarding_screen.dart';

class HydroFlowApp extends ConsumerWidget {
  const HydroFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydroControllerProvider);

    return MaterialApp(
      title: 'HydroFlow',
      debugShowCheckedModeBanner: false,
      theme: HydroTheme.light(state.settings.accent),
      darkTheme: HydroTheme.dark(state.settings.accent),
      themeMode: state.settings.themeMode,
      home: state.hasCompletedOnboarding
          ? const HydroShell()
          : const OnboardingScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:project_wellness/features/onboarding/onboarding_screen.dart';
import 'package:project_wellness/l10n/app_localizations.dart';
import 'package:project_wellness/repositories/profile_repository.dart';
import 'package:project_wellness/repositories/settings_repository.dart';

void main() {
  testWidgets('onboarding requires a name before continuing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProfileRepository()),
          ChangeNotifierProvider(create: (_) => SettingsRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(),
        ),
      ),
    );

    expect(find.text('Welcome to\nProject Wellness'), findsOneWidget);

    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pump();

    expect(find.text('Enter your name'), findsOneWidget);
  });
}

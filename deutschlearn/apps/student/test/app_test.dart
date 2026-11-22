import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student/src/app.dart';
import 'package:student/src/onboarding.dart';

void main() {
  testWidgets('without Supabase env the app shows "backend not configured"', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const StudentApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Backend nicht konfiguriert'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL is missing'), findsOneWidget);

    // The UI can still be explored; the welcome flow is reachable.
    await tester.tap(find.byKey(const Key('not-configured-preview')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('welcome-next')), findsOneWidget);
  });
}

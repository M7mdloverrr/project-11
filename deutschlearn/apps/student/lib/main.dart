import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';
import 'src/onboarding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = AppEnv.fromEnvironment();
  final client = await BackendBootstrap.initialize(env);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      retry: noRetry,
      overrides: [
        appEnvProvider.overrideWithValue(env),
        supabaseClientProvider.overrideWithValue(client),
        authRedirectUrlProvider.overrideWithValue('com.deutschlearn.student://auth-callback'),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const StudentApp(),
    ),
  );
}

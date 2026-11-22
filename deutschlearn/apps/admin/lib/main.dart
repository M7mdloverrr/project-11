import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'src/app.dart';
import 'src/set_password_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = AppEnv.fromEnvironment();
  // Read before Supabase consumes the tokens in the URL.
  final fromRecoveryLink = Uri.base.toString().contains('type=recovery');
  final client = await BackendBootstrap.initialize(env);
  runApp(
    ProviderScope(
      retry: noRetry,
      overrides: [
        appEnvProvider.overrideWithValue(env),
        supabaseClientProvider.overrideWithValue(client),
        // Password-reset e-mails for admins come back to this page.
        authRedirectUrlProvider.overrideWithValue('${Uri.base.origin}${Uri.base.path}'),
        allowedRolesProvider.overrideWithValue(const {Role.admin}),
        openedFromRecoveryLinkProvider.overrideWithValue(fromRecoveryLink),
      ],
      child: const AdminApp(),
    ),
  );
}

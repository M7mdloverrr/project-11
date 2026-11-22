import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'router.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'DeutschLearn Admin',
      debugShowCheckedModeBanner: false,
      theme: DLTheme.light(),
      darkTheme: DLTheme.dark(),
      locale: const Locale('en'),
      routerConfig: ref.watch(adminRouterProvider),
    );
  }
}
